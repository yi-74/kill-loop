extends RigidBody2D

signal speed_updated(speed: float)
signal energy_updated(current_energy: float)
signal combo_updated(combo_count: int)
signal combo_lost()
signal launch_failed()
signal wall_bounced(bounce_count: int, is_combo_lost: bool, impact_position: Vector2)
signal enemy_killed()
signal energy_bar_1_filled()
signal energy_bar_2_filled()
signal energy_bar_3_filled()

@export_group("Launch Power", "launch_")
@export var launch_multiplier: float = 7.0 #发射力度
@export var kill_threshold: float = 1500.0 #击杀速度
@export var default_max_speed: float = 4000.0 # 记录初始速度上限
@export var slow_mo_scale: float = 0.1 #子弹时间
@export_group("Energy System")
@export var energy_per_kill: float = 25.0   # 击杀敌人增加的能量
@export var energy_per_bounce: float = 35.0 # 反弹墙壁增加的能量
@export var energy_drain_per_second: float = 100.0 # 举例：每秒消耗**点能量
@export_group("Combo System")
@export var combo_max_bounces: int = 4       # 最大反弹容忍次数
@export var combo_speed_bonus: float = 250.0  # 每次连击成功，速度上限增加值
@export var combo_energy_bonus: float = 12.0 # 每次连击成功，额外能量奖励

@onready var line_2d: Line2D = $Line2D
@onready var kill_area: Area2D = $Area2D
@onready var death_audio_player: AudioStreamPlayer = $DeathAudioPlayer
@onready var visual_sprite: Sprite2D = $Sprite2D
@onready var trail_node: Line2D = $TrailwithLine2D
@onready var slow_mo_audio: AudioStreamPlayer = $SlowMoAudioPlayer
@onready var launch_audio: AudioStreamPlayer = $LaunchAudioPlayer
@onready var cancel_audio: AudioStreamPlayer = $CancelAudioPlayer
@onready var death_effect: ColorRect = get_node("/root/Main_tscn/DeathInversionEffect")
@onready var spawner = get_node("/root/Main_tscn/EnemySpawner") 
@onready var camera: Camera2D = get_node("/root/Main_tscn/Camera2D")
@onready var crt_effect: ColorRect = get_node("/root/Main_tscn/CanvasLayer/ColorRect") # 获取 CRT 特效

var is_dead: bool = false
var is_aiming: bool = false
var current_energy: float = 300.0 # 初始能量为满
var drag_start_position_screen: Vector2 = Vector2.ZERO
var velocity_before_impact: Vector2 = Vector2.ZERO
var current_combo: int = 0
var bounces_since_last_kill: int = 0
var has_killed_in_combo: bool = false
var current_max_speed: float = 0.0
var line_color_normal: Color = Color.WHITE
var line_color_low_energy: Color = Color("ff3b30") # 这是我们之前用过的那个红色
var line_color_tween: Tween # 用来控制颜色过渡的 Tween```


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	sleeping = false
	# 连接两个信号，分别处理不同逻辑
	kill_area.area_entered.connect(_on_kill_area_entered)
	body_entered.connect(_on_body_entered)
	current_max_speed = default_max_speed
	speed_updated.connect(on_speed_updated)




func _input(event: InputEvent) -> void:
	if is_dead: return

	# ... (右键取消的逻辑不变) ...

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		
		if event.is_pressed(): # --- 鼠标按下 ---
			if not is_aiming:
				# --- 【核心修正】移除能量检查，无条件进入子弹时间！ ---
				is_aiming = true
				Engine.time_scale = slow_mo_scale
				
				# ... (其他进入瞄准的逻辑保持不变)
				drag_start_position_screen = event.position
				line_2d.clear_points()
				line_2d.add_point(Vector2.ZERO); line_2d.add_point(Vector2.ZERO)
				if is_instance_valid(slow_mo_audio):
					slow_mo_audio.play()
				if has_method("fade_slow_mo_filter"):
					fade_slow_mo_filter(true)
		
		else: # --- 鼠标松开 ---
			if is_aiming:
				# 无论发射成功与否，瞄准都结束了，所以先执行所有“收尾”工作
				is_aiming = false
				Engine.time_scale = 1.0
				line_2d.clear_points()
				if is_instance_valid(slow_mo_audio):
					slow_mo_audio.stop()
				if has_method("fade_slow_mo_filter"):
					fade_slow_mo_filter(false)

				# --- 【门禁被移动到了这里】---
				# 只有在尝试发射时，才检查能量
				if current_energy < 100.0:
					print("能量不足！无法发射！")
					if is_instance_valid(cancel_audio):
						cancel_audio.play()
					launch_failed.emit()
					return # 能量不足，发射失败并结束

				# --- 如果能量足够，则执行发射 ---
				if is_instance_valid(launch_audio):
					launch_audio.play()
				
				_update_energy(current_energy - 100.0)

				var screen_drag_vector = event.position - drag_start_position_screen
				var launch_magnitude = screen_drag_vector.length() * launch_multiplier
				var mouse_world_pos = get_global_mouse_position()
				var world_direction_vector = (mouse_world_pos - global_position).normalized()
				linear_velocity = -world_direction_vector * launch_magnitude

				if linear_velocity.length_squared() > kill_threshold * kill_threshold:
					set_collision_mask_value(2, false)
				else:
					set_collision_mask_value(2, true)



func _process(delta: float) -> void:
	if is_aiming:
		var mouse_world_pos = get_global_mouse_position()
		var local_mouse_pos = to_local(mouse_world_pos)
		
		line_2d.set_point_position(1, local_mouse_pos)
		# 【新增】持续消耗能量
		var energy_before_drain = current_energy
		_update_energy(current_energy - (energy_drain_per_second * delta))
		
		# 【新增】持续消耗能量
		#    用我们之前创建的 _update_energy 函数，来安全地减少能量
		#    消耗的量 = 每秒消耗量 * 这一帧所经过的时间(delta)
		_update_energy(current_energy - (energy_drain_per_second * delta))
		# 【新增】检查能量是否耗尽
		if current_energy <= 0:
			print("能量耗尽，强制退出子弹时间！")
			# 我们可以创建一个新的函数来处理“取消瞄准”的逻辑，避免代码重复
			_cancel_aiming()
			return
			
		# --- 4. 【核心修正】在这里，每一帧都检查能量并更新颜色 ---
		# 判断当前能量是否低于“发射阈值”(100)
		if current_energy < 100.0:
			# 如果是，就将颜色 Tween 到“低能量”状态
			_tween_line_color(line_color_low_energy)
		else:
			# 否则，就将颜色 Tween 到“正常”状态
			_tween_line_color(line_color_normal)



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




# --- 在脚本中添加这个新的辅助函数 ---
func _cancel_aiming():
	if not is_aiming: return
	is_aiming = false
	Engine.time_scale = 1.0
	line_2d.clear_points()
	if is_instance_valid(slow_mo_audio): slow_mo_audio.stop()
	if is_instance_valid(cancel_audio): cancel_audio.play()
	if has_method("fade_slow_mo_filter"): fade_slow_mo_filter(false)




func on_speed_updated(current_speed: float):
	# 1. 调用颜色计算函数
	var target_color = get_color_for_speed(current_speed)
	
	# 2. 将计算出的颜色，应用到视觉节点上
	if is_instance_valid(visual_sprite):
		visual_sprite.modulate = target_color




func get_color_for_speed(speed: float) -> Color:
	# 【核心修正】我们现在使用 trail_node 这个变量来获取权威数据
	var low_thresh = trail_node.low_speed_threshold
	var high_thresh = trail_node.high_speed_threshold
	
	if speed <= low_thresh:
		return trail_node.low_speed_color
	elif speed < high_thresh:
		var progress = inverse_lerp(low_thresh, high_thresh, speed)
		return trail_node.low_speed_color.lerp(trail_node.mid_speed_color, progress)
	else:
		var super_speed_thresh = high_thresh + 500.0
		var progress = inverse_lerp(high_thresh, super_speed_thresh, speed)
		return trail_node.mid_speed_color.lerp(trail_node.high_speed_color, progress)



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
			
		# 检查是否跨越了 200
		if energy_before_update < 200.0 and current_energy >= 200.0:
			energy_bar_2_filled.emit()

		# 检查是否跨越了 300 (能量满了)
		if energy_before_update < 300.0 and current_energy >= 300.0:
			energy_bar_3_filled.emit()



func _on_kill_area_entered(area: Area2D):
	if is_dead: return
	var enemy_body = area.owner
	if velocity_before_impact.length_squared() > kill_threshold * kill_threshold:
		if enemy_body.has_method("die"):
			var impact_direction = velocity_before_impact.normalized()
			enemy_body.die(impact_direction)
			call_deferred("trigger_kill_slow_motion", 0.15, 0.2)
			enemy_killed.emit()
			
			# --- 【核心修改】在这里触发屏幕抖动！ ---
			if is_instance_valid(camera):
				camera.apply_shake(6.0)
			
			# --- 每次成功击杀，都重置“撞墙计数器” ---
			bounces_since_last_kill = 0
			enemy_killed.emit()
			
			# --- 增加 Combo ---
			current_combo += 1
			combo_updated.emit(current_combo)

			current_max_speed = default_max_speed + (current_combo * combo_speed_bonus)
			# -----------------------------------------------------------------

			# 给予能量奖励 (这个逻辑可以保持不变，也可以同样做成累积的)
			_update_energy(current_energy + combo_energy_bonus)
			
			# 增加基础的击杀能量
			_update_energy(current_energy + energy_per_kill)
			
		# 【核心修改】通知 Spawner 加分
			spawner.add_score(enemy_body.base_score_value, current_combo, enemy_body.global_position)
			enemy_body.die(impact_direction)



func _on_body_entered(body: Node):
	if is_dead: return

	# --- 【核心修正】计算精确的近似碰撞点 ---
	
	# 1. 获取玩家碰撞体的半径 (假设是圆形)
	var player_radius = $CollisionShape2D.shape.radius * global_scale.x
	
	# 2. 获取玩家撞击墙壁时的方向
	var impact_direction = velocity_before_impact.normalized()
	
	# 3. 精确的碰撞点 ≈ 玩家的中心位置 + 沿着撞击方向延伸一个半径的距离
	var impact_position = global_position + impact_direction * player_radius

	# --- 后续的所有逻辑，都使用这个新的、更精确的 impact_position ---
	
	if body.is_in_group("enemy"):
		if velocity_before_impact.length_squared() < kill_threshold * kill_threshold:
			_player_death_sequence()
		return

	if body.is_in_group("bouncing_enemy"):
		return
			
	# 如果是墙壁
	var is_combo_lost_this_hit = false
	if not has_killed_in_combo:
		bounces_since_last_kill += 1
		if bounces_since_last_kill >= combo_max_bounces:
			is_combo_lost_this_hit = true
			
	wall_bounced.emit(bounces_since_last_kill, is_combo_lost_this_hit, impact_position)
			
	if is_combo_lost_this_hit:
		lose_combo()
	
	_update_energy(current_energy + energy_per_bounce)



func lose_combo():
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



func _tween_line_color(target_color: Color):
	# --- 【核心优化】 ---
	
	# 1. 检查：如果线的【当前颜色】已经是我们想要的【目标颜色】了，
	#    那就没必要再播放动画了，直接结束函数。
	if line_2d.default_color == target_color:
		return

	# 2. 检查：如果【已经有一个颜色过渡动画】正在朝向我们的目标颜色播放，
	#    那也没必要再创建一个新的了，同样直接结束函数。
	if is_instance_valid(line_color_tween) and line_color_tween.is_running():
		# 这个检查更复杂，我们先用一个更简单的方法
		pass # 我们先简化逻辑

	# --- 如果颜色确实需要改变，才执行后续的动画逻辑 ---
	
	# a) 先杀死任何可能还在运行的旧动画
	if is_instance_valid(line_color_tween):
		line_color_tween.kill()
	
	# b) 创建一个新的 Tween
	line_color_tween = create_tween()
	line_color_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# c) 播放颜色过渡动画
	line_color_tween.tween_property(line_2d, "default_color", target_color, 0.003)



# --- 添加全新的、简化的滤镜控制函数 ---
func fade_slow_mo_filter(turn_on: bool):
	if not is_instance_valid(crt_effect) or not crt_effect.material: return

	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	var final_mix_value = 1.0 if turn_on else 0.0
	
	# 我们只对 "slow_mo_mix" 这一个参数进行动画
	tween.tween_method(
		func(v): crt_effect.material.set_shader_parameter("slow_mo_mix", v),
		crt_effect.material.get_shader_parameter("slow_mo_mix"),
		final_mix_value,
		0.2
	)



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
