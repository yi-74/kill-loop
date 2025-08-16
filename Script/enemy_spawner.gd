# enemy_spawner.gd
extends Node

# --- 可在编辑器中指定的参数 ---
@export var spawn_zone_path: NodePath
@export var min_spawn_distance: float = 200.0
@export var spawn_prep_time: float = 1.0

# --- 节点引用 ---
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_zone: Area2D = get_node(spawn_zone_path)
@onready var spawn_zone_shape: CollisionShape2D = spawn_zone.get_child(0)

# --- 内部变量 ---
var game_time: float = 0.0
var wave_data: Array = []
var current_wave: Dictionary
var enemy_scenes: Dictionary = {
	"EnemyNormal": preload("res://game/actors/enemy/enemy_normal.tscn"),
	"EnemyTracker": preload("res://game/actors/enemy/enemy_tracker.tscn"),
	"EnemyPatrol": preload("res://game/actors/enemy/enemy_patrol.tscn")
}
const SpawnMarker = preload("res://game/effect/spawn_marker.tscn")


func _ready() -> void:
	# 1. 加载并解析 JSON 数据
	var file = FileAccess.open("res://spawn_waves.json", FileAccess.READ)
	var json_data = JSON.parse_string(file.get_as_text())
	wave_data = json_data.waves
	file.close()

	# 2. 连接计时器信号
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# 3. 初始化第一波
	_update_wave()


func _process(delta: float) -> void:
	# 1. 更新游戏时间
	game_time += delta
	
	# 2. 检查是否需要切换到下一波
	if game_time > current_wave.end_time and wave_data.size() > 1:
		wave_data.pop_front() # 移除已经过期的波次
		_update_wave()
		
	# 3. 检查是否需要补充敌人
	_check_and_spawn()


func _update_wave() -> void:
	if wave_data.is_empty():
		print("所有波次已结束!")
		set_process(false) # 停止生成器
		return
		
	current_wave = wave_data[0]
	print("进入新波次! 时间: ", current_wave.start_time, "s")
	# 立即触发一次生成检查
	_check_and_spawn()


func _check_and_spawn() -> void:
	# 如果计时器正在运行，说明正在等待生成，则不进行操作
	if not spawn_timer.is_stopped():
		return

	var current_enemy_count = get_tree().get_nodes_in_group("enemy").size()
	
	# 如果敌人数量低于下限，或者未达到上限，则准备生成
	if current_enemy_count < current_wave.min_enemies or current_enemy_count < current_wave.max_enemies:
		# 设置一个随机的生成间隔
		var interval = randf_range(current_wave.min_interval, current_wave.max_interval)
		spawn_timer.wait_time = interval
		spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	var current_enemy_count = get_tree().get_nodes_in_group("enemy").size()
	if current_enemy_count >= current_wave.max_enemies:
		return # 如果在等待期间敌人数量已满，则此次不生成

	# 1. 选择要生成的敌人类型
	var enemy_to_spawn_name = _pick_enemy_from_pool()
	var enemy_scene = enemy_scenes[enemy_to_spawn_name]
	
	# 2. 寻找一个安全的生成位置
	var spawn_pos = _find_safe_spawn_position()
	if spawn_pos == Vector2.INF: # 如果找不到安全位置
		print("找不到安全的生成位置，稍后重试。")
		spawn_timer.start() # 立即重新开始计时
		return

	# 3. 生成“出生标记”
	var marker = SpawnMarker.instantiate()
	get_parent().add_child(marker)
	marker.global_position = spawn_pos
	# 将参数传递给标记
	marker.spawn_duration = spawn_prep_time
	marker.enemy_scene = enemy_scene
	marker.spawn_position = spawn_pos


func _pick_enemy_from_pool() -> String:
	var rand_val = randf()
	var cumulative = 0.0
	for enemy_name in current_wave.enemy_pool:
		cumulative += current_wave.enemy_pool[enemy_name]
		if rand_val < cumulative:
			return enemy_name
	return ""


func _find_safe_spawn_position() -> Vector2:
	# --- 1. 获取生成区域的矩形资源 ---
	#    这通常是一个 RectangleShape2D
	var spawn_shape_resource = spawn_zone_shape.shape
	if not spawn_shape_resource is RectangleShape2D:
		print("SpawnZone's CollisionShape2D is not a RectangleShape2D!")
		return Vector2.INF

	var spawn_rect_local: Rect2 = spawn_shape_resource.get_rect()
	
	# --- 2. 计算生成区域在世界中的位置和大小 ---
	#    矩形的原点 (position) 是它的中心点
	var spawn_rect_world_center = spawn_zone.global_position
	var spawn_rect_world_size = spawn_rect_local.size * spawn_zone.global_scale

	#    计算出矩形在世界坐标系中的左上角 (top-left corner)
	var spawn_rect_world_origin = spawn_rect_world_center - spawn_rect_world_size / 2.0

	# --- 【新增 Print 调试语句】 ---
	print("---------- 生成位置诊断 ----------")
	print("SpawnZone (Area2D) 的世界中心位置: ", spawn_rect_world_center)
	print("SpawnZone 矩形资源的局部大小: ", spawn_rect_local.size)
	print("SpawnZone 的全局缩放: ", spawn_zone.global_scale)
	print("计算出的世界大小: ", spawn_rect_world_size)
	print("计算出的世界左上角 (Origin): ", spawn_rect_world_origin)
	
	# 尝试最多 10 次来寻找一个好位置
	for i in range(10):
		# 在世界坐标范围内生成一个随机点
		var rand_pos = Vector2(
			randf_range(spawn_rect_world_origin.x, spawn_rect_world_origin.x + spawn_rect_world_size.x),
			randf_range(spawn_rect_world_origin.y, spawn_rect_world_origin.y + spawn_rect_world_size.y)
		)
		
		print("尝试第 ", i+1, " 次, 随机位置: ", rand_pos)

		var is_safe = true
		var enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			if enemy.global_position.distance_to(rand_pos) < min_spawn_distance:
				is_safe = false
				break
		
		if is_safe:
			print("成功找到安全位置: ", rand_pos)
			print("------------------------------")
			return rand_pos
			
	print("尝试10次后，仍未找到安全位置。")
	print("------------------------------")
	return Vector2.INF # 代表失败
