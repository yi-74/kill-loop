# enemy_spawner.gd
extends Node

# --- 【新增】定义一个新的信号，用来广播格式化后的时间字符串 ---
signal game_time_updated(time_float: float)
signal score_updated(new_score: int)

# --- 可在编辑器中指定的参数 ---
@export var spawn_zone_path: NodePath
@export var min_spawn_distance: float = 200.0
@export var spawn_prep_time: float = 1.0

# --- 节点引用 ---
@onready var path_manager = $"/root/Main_tscn/PathManager" # 使用绝对路径获取
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_zone: Area2D = get_node(spawn_zone_path)
@onready var spawn_zone_shape: CollisionShape2D = spawn_zone.get_child(0)

# --- 内部变量 ---
var current_score: int = 0
var game_time: float = 0.0
var wave_data: Array = []
var current_wave: Dictionary
var enemy_scenes: Dictionary = {
	"EnemyNormal": preload("res://game/actors/enemy/enemy_normal.tscn"),
	"EnemyTracker": preload("res://game/actors/enemy/enemy_tracker.tscn"),
	"EnemyPatrol": preload("res://game/actors/enemy/enemy_patrol.tscn")
}
const SpawnMarker = preload("res://game/effect/spawn_marker.tscn")
const FloatingText = preload("res://game/effect/floating_text.tscn")



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
		# --- 【新增】格式化时间并发出信号 ---
	game_time_updated.emit(game_time)
	
	# 2. 检查是否需要切换到下一波
	if game_time > current_wave.end_time and wave_data.size() > 1:
		wave_data.pop_front() # 移除已经过期的波次
		_update_wave()
		
	# 3. 检查是否需要补充敌人
	_check_and_spawn()



# --- 【新增】添加分数的函数 ---
func add_score(base_score: int, combo: int, position: Vector2):
	# 1. 计算连击加成
	var combo_multiplier = 1.0 + min(0.05 * combo, 1.0) # min(..., 1.0) 实现了 x2 的软上限
	var final_score = int(base_score * combo_multiplier)
	
	# 2. 更新当前总分
	var old_score = current_score
	current_score += final_score
	
	# 3. 检查是否打破最高分
	if current_score > DataManager.high_score and old_score <= DataManager.high_score:
		print("打破最高分记录！")
	
	# 4. 更新并保存最高分
	DataManager.report_new_score(current_score)
	
	# 5. 发出分数更新信号，通知 UI
	score_updated.emit(current_score)
	
	# 6. 生成飘字
	var ft = FloatingText.instantiate()
	get_parent().add_child(ft) # 添加到主场景
	ft.global_position = position
	ft.setup(final_score)



func _update_wave() -> void:
	if wave_data.is_empty():
		set_process(false) # 停止生成器
		return
		
	current_wave = wave_data[0]
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
		return

	# 1. 选择要生成的敌人类型
	var enemy_to_spawn_name = _pick_enemy_from_pool()
	var enemy_scene = enemy_scenes[enemy_to_spawn_name]
	
	# --- 【核心修正】统一所有敌人的生成前逻辑 ---
	
	var spawn_pos: Vector2
	var patrol_path_for_enemy: Path2D = null

	if enemy_to_spawn_name == "EnemyPatrol":
		patrol_path_for_enemy = path_manager.request_free_path()
		if not patrol_path_for_enemy:
			# 降级处理：如果没路径，就改成生成普通敌人
			enemy_to_spawn_name = "EnemyNormal"
			enemy_scene = enemy_scenes["EnemyNormal"]
			spawn_pos = _find_safe_spawn_position()
		else:
			# 巡逻敌人的出生点，就是其路径的第一个点（世界坐标）
			spawn_pos = patrol_path_for_enemy.curve.get_point_position(0)
			spawn_pos = patrol_path_for_enemy.to_global(spawn_pos)
			
			# 我们依然要检查这个出生点是否安全！
			if not _is_position_safe(spawn_pos):
				path_manager.release_path(patrol_path_for_enemy) # 释放占用的路径
				return
	else:
		# 对于其他敌人，正常寻找随机安全位置
		spawn_pos = _find_safe_spawn_position()

	# 如果最终都找不到安全位置，则取消本次生成
	if spawn_pos == Vector2.INF:
		# 如果之前为巡逻敌人预定了路径，要记得释放掉
		if patrol_path_for_enemy:
			path_manager.release_path(patrol_path_for_enemy)
		return

	# --- 3. 统一使用“出生标记”来生成 ---
	var marker = SpawnMarker.instantiate()
	get_parent().add_child(marker)
	marker.global_position = spawn_pos
	
	# 将所有需要的参数都传递给标记
	marker.spawn_duration = spawn_prep_time
	marker.enemy_scene = enemy_scene
	marker.spawn_position = spawn_pos
	
	# 如果是巡逻敌人，则额外传递路径信息
	if patrol_path_for_enemy:
		marker.patrol_path_to_assign = patrol_path_for_enemy
		marker.path_manager_ref = path_manager



func _is_position_safe(pos_to_check: Vector2) -> bool:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.global_position.distance_to(pos_to_check) < min_spawn_distance:
			return false # 不安全
	return true # 安全



func _pick_enemy_from_pool() -> String:
	var rand_val = randf()
	var cumulative = 0.0
	for enemy_name in current_wave.enemy_pool:
		cumulative += current_wave.enemy_pool[enemy_name]
		if rand_val < cumulative:
			return enemy_name
	return ""



func _find_safe_spawn_position() -> Vector2:
	
	# 1. 获取生成区域碰撞体（CollisionShape2D）的形状资源（Shape）
	#    这个形状资源（比如 RectangleShape2D）内部，才存储着真正的尺寸信息。
	var spawn_shape_resource = spawn_zone_shape.shape
	
	# 2. 获取这个形状资源的【局部】矩形范围。
	#    例如，一个大小为 (1920, 1080) 的矩形，它的 get_rect() 结果
	#    通常是 Rect2( -960, -540, 1920, 1080 )，
	#    因为它的大小是从中心点向两边延伸的。
	var local_rect = spawn_shape_resource.get_rect()
	
	# 3. 我们进行多次尝试（比如 20 次），以提高找到安全位置的几率。
	for i in range(20):
		
		# 4. 在这个【局部】矩形的范围内，生成一个随机的【局部】点。
		#    randf_range() 会在两个数之间取一个随机浮点数。
		var random_local_pos = Vector2(
			randf_range(local_rect.position.x, local_rect.end.x),
			randf_range(local_rect.position.y, local_rect.end.y)
		)
		
		# 5. 将这个【局部】点，转换为【世界】坐标。
		#    to_global() 是最关键的函数，它会自动处理所有偏移和缩放。
		var random_world_pos = spawn_zone.to_global(random_local_pos)
		
		# 6. 调用我们的辅助函数，检查这个新生成的随机世界坐标是否“安全”。
		if _is_position_safe(random_world_pos):
			# a) 如果安全，太好了！我们立刻返回这个有效的位置，并结束函数。
			return random_world_pos
			
	# 7. 如果循环了 20 次，都没有找到一个安全的位置（通常是因为场上敌人太密集了）
	return Vector2.INF
