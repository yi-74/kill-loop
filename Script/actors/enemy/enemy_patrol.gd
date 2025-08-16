# ===================================================================
# EnemyPatrol.gd - V2.0 (路径外部指定版)
# ===================================================================
extends RigidBody2D

# --- 可在编辑器中调整的参数 ---
@export var move_speed: float = 150.0
@export var turn_rate: float = 5.0

# --- 【核心修改】导出一个 NodePath 变量，用来在编辑器里指定路径 ---
@export var patrol_path: NodePath

# --- 内部变量 ---
var path_points: PackedVector2Array
var current_target_index: int = 1
var move_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 安全检查：检查路径是否被指定
	if patrol_path.is_empty():
		set_physics_process(false)
		return

	# 通过路径获取 Path2D 节点
	var path_node = get_node(patrol_path)
	if not path_node is Path2D:
		set_physics_process(false)
		return

	# 【核心修改】路径点现在是【世界坐标】，因为路径在主场景中
	path_points = path_node.curve.get_baked_points()
	
	# 将路径的局部坐标点，转换为世界坐标点
	var path_world_transform = path_node.global_transform
	for i in range(path_points.size()):
		path_points[i] = path_world_transform * path_points[i]

	if path_points.size() < 2:
		set_physics_process(false)
		return
		
	# 将自己的【世界】初始位置，设置为路径的第一个点
	global_position = path_points[0]

func _physics_process(delta: float) -> void:
	var target_position = path_points[current_target_index]
	
	# 【核心修改】现在所有的位置计算，都使用世界坐标
	move_direction = (target_position - global_position).normalized()
	
	linear_velocity = move_direction * move_speed
	
	var target_angle = move_direction.angle()
	rotation = lerp_angle(rotation, target_angle + PI/2.0, delta * turn_rate)
	
	if global_position.distance_to(target_position) < 10.0:
		current_target_index += 1
		if current_target_index >= path_points.size():
			path_points.reverse()
			current_target_index = 1


# --- 死亡逻辑 (与 EnemyNormal 完全一样) ---
const KillEffect = preload("res://game/effect/kill_effect.tscn")

func die(impact_direction: Vector2) -> void:
	var effect_instance = KillEffect.instantiate()
	
	effect_instance.rotation = impact_direction.angle() + PI / 2.0
	effect_instance.global_position = self.global_position
	
	get_parent().add_child(effect_instance)
	
	queue_free()
