extends RigidBody2D

signal speed_updated(speed: float)
signal energy_updated(current_energy: float)
signal combo_updated(combo_count: int)
signal combo_lost()

@export_group("Launch Power", "launch_")
@export var launch_multiplier: float = 7.0 #发射力度
@export var kill_threshold: float = 1000.0 #击杀速度
@export var default_max_speed: float = 4000.0 # 记录初始速度上限
@export var slow_mo_scale: float = 0.1 #子弹时间
@export_group("Energy System")
@export var energy_per_kill: float = 30.0   # 击杀敌人增加的能量
@export var energy_per_bounce: float = 10.0 # 反弹墙壁增加的能量
@export_group("Combo System")
@export var combo_max_bounces: int = 2       # 最大反弹容忍次数
@export var combo_speed_bonus: float = 10.0  # 每次连击成功，速度上限增加值
@export var combo_energy_bonus: float = 10.0 # 每次连击成功，额外能量奖励

@onready var line_2d: Line2D = $Line2D
@onready var kill_area: Area2D = $Area2D

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
				bounces_since_last_kill = 0
				has_killed_in_combo = false
				
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
	# 将能量限制在 0 到 300 之间
	current_energy = clamp(new_energy, 0.0, 300.0)
	# 发出信号，通知 UI 更新
	energy_updated.emit(current_energy)



# 在 PlayerBall.gd 的 _on_kill_area_entered 函数中

# 请用这个完整的版本，替换您现有的 _on_kill_area_entered 函数

func _on_kill_area_entered(area: Area2D):
	var enemy_body = area.owner
	if velocity_before_impact.length_squared() > kill_threshold * kill_threshold:
		if enemy_body.has_method("die"):
			# 1. 计算撞击方向
			var impact_direction = velocity_before_impact.normalized()
			# 2. 命令敌人死亡，并传递方向
			enemy_body.die(impact_direction)
			# 3. 触发击杀慢动作
			call_deferred("trigger_kill_slow_motion", 0.15, 0.2)
			
			# 标记本次发射已造成击杀
			has_killed_in_combo = true

			# 每次击杀，都直接增加 Combo，并给予奖励
			print("连击成功! Combo +1")
			current_combo += 1
			combo_updated.emit(current_combo)
			
			# 给予奖励
			current_max_speed += combo_speed_bonus
			_update_energy(current_energy + combo_energy_bonus)
			
			# 增加基础的击杀能量
			_update_energy(current_energy + energy_per_kill)



func _on_body_entered(body: Node):
	# 低速撞敌人的逻辑保持不变
	if body.is_in_group("enemy"):
		if velocity_before_impact.length_squared() < kill_threshold * kill_threshold:
			lose_combo()
		return

	# 撞弹射敌人的逻辑保持不变
	if body.is_in_group("bouncing_enemy"):
		return
			
	# --- 如果撞到的是墙壁 ---
	
	# 只有在本次发射还【没有】击杀过任何敌人的情况下，撞墙才会计数
	if not has_killed_in_combo:
		bounces_since_last_kill += 1
		
		# 检查连击是否因为“连续撞墙”而中断
		if bounces_since_last_kill >= combo_max_bounces:
			lose_combo()
	
	# 增加反弹能量 (无论如何都应该增加)
	_update_energy(current_energy + energy_per_bounce)



func lose_combo():
	if current_combo > 0: # 只有在有连击数时才触发“中断”
		current_combo = 0
		combo_updated.emit(current_combo)
		combo_lost.emit() # 发出“连击已中断”的信号
		
		# 重置速度上限
		current_max_speed = default_max_speed
	
	# 重置计数器
	bounces_since_last_kill = 0
	has_killed_in_combo = false



func trigger_kill_slow_motion(duration: float, time_scale_during_slow_mo: float = 0.2):
	var original_time_scale = Engine.time_scale
	Engine.time_scale = time_scale_during_slow_mo
	await get_tree().create_timer(duration, true, false, true).timeout
	if is_aiming:
		Engine.time_scale = slow_mo_scale
	else:
		Engine.time_scale = 1.0
