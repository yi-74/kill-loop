extends RigidBody2D

signal speed_updated(speed: float)
signal energy_updated(current_energy: float)
signal combo_updated(combo_count: int)
signal combo_lost()
signal wall_bounced(bounce_count: int, is_combo_lost: bool)
signal energy_bar_1_filled()
signal energy_bar_2_filled()
signal energy_bar_3_filled()

@export_group("Launch Power", "launch_")
@export var launch_multiplier: float = 7.0 #发射力度
@export var kill_threshold: float = 1500.0 #击杀速度
@export var default_max_speed: float = 4000.0 # 记录初始速度上限
@export var slow_mo_scale: float = 0.1 #子弹时间
@export_group("Energy System")
@export var energy_per_kill: float = 20.0   # 击杀敌人增加的能量
@export var energy_per_bounce: float = 30.0 # 反弹墙壁增加的能量
@export_group("Combo System")
@export var combo_max_bounces: int = 4       # 最大反弹容忍次数
@export var combo_speed_bonus: float = 250.0  # 每次连击成功，速度上限增加值
@export var combo_energy_bonus: float = 12.0 # 每次连击成功，额外能量奖励

@onready var line_2d: Line2D = $Line2D
@onready var kill_area: Area2D = $Area2D
@onready var death_effect: ColorRect = get_node("/root/Main_tscn/DeathInversionEffect")
@onready var spawner = get_node("/root/Main_tscn/EnemySpawner") 
@onready var camera: Camera2D = get_node("/root/Main_tscn/Camera2D")
@onready var death_audio_player: AudioStreamPlayer = $DeathAudioPlayer

var is_dead: bool = false
var is_aiming: bool = false
var current_energy: float = 300.0 # 初始能量为满
var drag_start_position_screen: Vector2 = Vector2.ZERO
var velocity_before_impact: Vector2 = Vector2.ZERO
var current_combo: int = 0
var bounces_since_last_kill: int = 0
var has_killed_in_combo: bool = false
var current_max_speed: float = 0.0


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	sleeping = false
	# 连接两个信号，分别处理不同逻辑
	kill_area.area_entered.connect(_on_kill_area_entered)
	body_entered.connect(_on_body_entered)
	current_max_speed = default_max_speed



func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if not is_aiming:
				is_aiming = true
				drag_start_position_screen = event.position
				Engine.time_scale = slow_mo_scale
				line_2d.clear_points()
				line_2d.add_point(Vector2.ZERO); line_2d.add_point(Vector2.ZERO)
		else: 
			if is_aiming:
				if current_energy < 100.0: # --- 发射前检查能量 ---
					print("能量不足！无法发射！")
					is_aiming = false
					Engine.time_scale = 1.0
					line_2d.clear_points()
					return
				
				is_aiming = false # --- 如果能量足够，执行后续操作 ---
				Engine.time_scale = 1.0
				line_2d.clear_points()
				
				_update_energy(current_energy - 100.0) #消耗能量

				var screen_drag_vector = event.position - drag_start_position_screen
				var launch_magnitude = screen_drag_vector.length() * launch_multiplier
				var mouse_world_pos = get_global_mouse_position()
				var world_direction_vector = (mouse_world_pos - global_position).normalized()
				linear_velocity = -world_direction_vector * launch_magnitude

				# 根据速度，决定是否开启“穿透模式”（即关闭物理碰撞）
				if linear_velocity.length_squared() > kill_threshold * kill_threshold:
					set_collision_mask_value(2, false) # 关闭对第2层(enemies_solid)的检测
				else:
					set_collision_mask_value(2, true)



func _process(delta: float) -> void:
	if is_aiming:
		var mouse_world_pos = get_global_mouse_position()
		var local_mouse_pos = to_local(mouse_world_pos)
		line_2d.set_point_position(1, local_mouse_pos)



func _physics_process(delta: float) -> void:
	velocity_before_impact = linear_velocity
	if not is_aiming and linear_velocity.length_squared() < 1.0:
		if not get_collision_mask_value(2):
			set_collision_mask_value(2, true)
	if linear_velocity.length() > current_max_speed:
		linear_velocity = linear_velocity.normalized() * current_max_speed
	# 当速度慢下来时，恢复物理碰撞能力
	if not is_aiming and linear_velocity.length_squared() < 1.0:
		if not get_collision_mask_value(2): # 第2层是 enemies_solid
			set_collision_mask_value(2, true)
	# 发出信号 --- 我们用 .length() 获取当前速度的大小，并用 int() 把它变成整数，方便显示
	speed_updated.emit(int(linear_velocity.length()))



func _update_energy(new_energy: float):
	# --- 1. 记录更新前的能量值 ---
	var energy_before_update = current_energy

	# --- 2. 更新并限制能量值 (与之前相同) ---
	current_energy = clamp(new_energy, 0.0, 300.0)
	
	# --- 3. 发出常规的能量更新信号，让 UI 能量条刷新 (与之前相同) ---
	energy_updated.emit(current_energy)
	
	# -----------------------------------------------------------------
	# --- 4. 【核心】检查是否【向上】跨越了阈值 ---
	# -----------------------------------------------------------------
	# 只有在能量是【增加】的情况下，才进行检查
	if current_energy > energy_before_update:
		
		# 检查是否跨越了 100
		if energy_before_update < 100.0 and current_energy >= 100.0:
			energy_bar_1_filled.emit()
			print("能量达到 100! 触发动画1")
			
		# 检查是否跨越了 200
		if energy_before_update < 200.0 and current_energy >= 200.0:
			energy_bar_2_filled.emit()
			print("能量达到 200! 触发动画2")
			
		# 检查是否跨越了 300 (能量满了)
		if energy_before_update < 300.0 and current_energy >= 300.0:
			energy_bar_3_filled.emit()
			print("能量达到 300! 触发动画3")



func _on_kill_area_entered(area: Area2D):
	if is_dead: return
	var enemy_body = area.owner
	if velocity_before_impact.length_squared() > kill_threshold * kill_threshold:
		if enemy_body.has_method("die"):
			var impact_direction = velocity_before_impact.normalized()
			enemy_body.die(impact_direction)
			call_deferred("trigger_kill_slow_motion", 0.15, 0.2)
			
			# --- 【核心修改】在这里触发屏幕抖动！ ---
			if is_instance_valid(camera):
				camera.apply_shake(6.0)
			
			# --- 每次成功击杀，都重置“撞墙计数器” ---
			bounces_since_last_kill = 0
			
			# --- 增加 Combo ---
			current_combo += 1
			print("连击成功! 当前 Combo: ", current_combo)
			combo_updated.emit(current_combo)

			current_max_speed = default_max_speed + (current_combo * combo_speed_bonus)
			print("速度上限提升! 新上限: ", current_max_speed)
			# -----------------------------------------------------------------

			# 给予能量奖励 (这个逻辑可以保持不变，也可以同样做成累积的)
			_update_energy(current_energy + combo_energy_bonus)
			
			# 增加基础的击杀能量
			_update_energy(current_energy + energy_per_kill)
			
		# 【核心修改】通知 Spawner 加分
			spawner.add_score(enemy_body.base_score_value, current_combo, enemy_body.global_position)
			enemy_body.die(impact_direction)



func _on_body_entered(body: Node):
	# 只有在【低速】撞到敌人时，才会触发死亡
	if body.is_in_group("enemy"):
		if velocity_before_impact.length_squared() < kill_threshold * kill_threshold:
			print("速度不足，玩家死亡！")
			# 【核心修正】不再是 queue_free()，而是调用我们的死亡演出
			_player_death_sequence()
		return

	if body.is_in_group("bouncing_enemy"):
		return
			
	# 如果撞到的是墙壁，处理连击逻辑
	var is_combo_lost_this_hit = false # 先假设本次撞击不会中断连击
	if not has_killed_in_combo:
		bounces_since_last_kill += 1
		wall_bounced.emit()
		if bounces_since_last_kill >= combo_max_bounces:
			print("PlayerBall: 反弹次数超限，准备中断连击！") # <-- 添加这行
			is_combo_lost_this_hit = true
			lose_combo()

		# --- 【核心修改】发出带有详细信息的信号 ---
		wall_bounced.emit(bounces_since_last_kill, is_combo_lost_this_hit)
		
		# 在发出信号之后，再执行中断逻辑
		if is_combo_lost_this_hit:
			lose_combo()
	
	_update_energy(current_energy + energy_per_bounce)



func lose_combo():
	print("PlayerBall: lose_combo() 函数被调用！") # <-- 添加这行
	if current_combo > 0:
		current_combo = 0
		combo_updated.emit(current_combo)
		combo_lost.emit()
		
		current_max_speed = default_max_speed
	
	bounces_since_last_kill = 0 # 重置“撞墙计数器”



func trigger_kill_slow_motion(duration: float, time_scale_during_slow_mo: float = 0.2):
	var original_time_scale = Engine.time_scale
	Engine.time_scale = time_scale_during_slow_mo
	await get_tree().create_timer(duration, true, false, true).timeout
	if is_aiming:
		Engine.time_scale = slow_mo_scale
	else:
		Engine.time_scale = 1.0



func _player_death_sequence():
	# 1. 安全检查 (保持不变)
	if is_dead:
		return
	is_dead = true
	
	# --- 【核心修改】在函数的最开始，立刻播放死亡音效 ---
	if is_instance_valid(death_audio_player):
		death_audio_player.play()
		
	lose_combo()

	Engine.time_scale = 1.0
	
	# 2. 立即暂停游戏
	get_tree().paused = true
	
	# 3. 创建一个可以在暂停时运行的 Tween
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE)

	# 4. 编排死亡动画序列
	tween.tween_property(death_effect, "modulate:a", 1.0, 0.3)
	tween.tween_interval(0.4)
	tween.tween_property(death_effect, "modulate:a", 0.0, 0.3)
	
	death_effect.show()

	# 5. 等待整个动画序列播放完毕
	await tween.finished
	
	# 6. 恢复与重启
	death_effect.hide()
	get_tree().paused = false
	get_tree().reload_current_scene()
