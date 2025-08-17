# ===================================================================
# TrailWithLine2D.gd (V_SIGNAL_DRIVEN - 最终信号驱动版)
# ===================================================================
extends Line2D

# --- 拖尾基础参数 ---
@export var point_count: int = 25
@export var min_distance: float = 15.0
@export var is_enabled: bool = true

# --- 【新】颜色参数现在直接在这里定义 ---
var low_speed_color: Color = Color("ff3b30")
var mid_speed_color: Color = Color("ffffff")
var high_speed_color: Color = Color("00ffff")
var low_speed_threshold: float = 1500.0
var high_speed_threshold: float = 3000.0

# --- 内部变量 ---
var parent_node: Node2D
var last_point_position: Vector2 = Vector2.INF

func _ready() -> void:
	if get_parent() is Node2D:
		parent_node = get_parent()
		# 【核心】让拖尾脚本“订阅”父节点(PlayerBall)的速度更新信号
		if parent_node.has_signal("speed_updated"):
			parent_node.speed_updated.connect(on_player_speed_updated)
		else:
			push_error("Parent node does not have a 'speed_updated' signal.")
			
	else:
		is_enabled = false
		push_error("Trail's parent is not a Node2D.")
		return

	if not gradient: gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color.BLACK, Color.WHITE])


func _process(delta: float) -> void:
	# _process 只负责画点，不再关心颜色
	if not is_enabled or not is_instance_valid(parent_node):
		if get_point_count() > 0: remove_point(get_point_count() - 1)
		return

	global_position = Vector2.ZERO
	global_rotation = 0

	var parent_pos = parent_node.global_position
	if parent_pos.distance_to(last_point_position) > min_distance:
		add_point(parent_pos)
		last_point_position = parent_pos
		while get_point_count() > point_count:
			remove_point(0)

# --- 【新】这是响应信号的新函数 ---
func on_player_speed_updated(current_speed: float):
	var target_color = get_color_for_speed(current_speed)
	
	gradient.set_color(1, target_color)
	
	var tail_color = target_color
	tail_color.a = 0.0
	gradient.set_color(0, tail_color)

# --- 颜色计算逻辑被保留，但只在接收到信号时才调用 ---
func get_color_for_speed(speed: float) -> Color:
	if speed <= low_speed_threshold:
		return low_speed_color
	elif speed < high_speed_threshold:
		var progress = inverse_lerp(low_speed_threshold, high_speed_threshold, speed)
		return low_speed_color.lerp(mid_speed_color, progress)
	else:
		var super_speed_threshold = high_speed_threshold + 2000.0
		var progress = inverse_lerp(high_speed_threshold, super_speed_threshold, speed)
		return mid_speed_color.lerp(high_speed_color, progress)
