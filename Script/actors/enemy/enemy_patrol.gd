# ===================================================================
# EnemyPatrol.gd - V2.0 (路径外部指定版)
# ===================================================================
extends RigidBody2D

# --- 可在编辑器中调整的参数 ---
@export var base_score_value: int = 130
@export var move_speed: float = 350.0
@export var turn_rate: float = 5.0

var assigned_path: Path2D = null # 用来存储被分配的路径
var path_manager = null # 用来存储对路径管理器的引用
var path_points: PackedVector2Array
var current_target_index: int = 1
var move_direction: Vector2 = Vector2.ZERO



func initialize(path: Path2D, manager):
	assigned_path = path
	path_manager = manager
	
	# 将 _ready() 中的逻辑移动到这里
	if not is_instance_valid(assigned_path):
		set_physics_process(false)
		return
		
	var path_points_local = assigned_path.curve.get_baked_points()
	var path_world_transform = assigned_path.global_transform
	for p in path_points_local:
		path_points.append(path_world_transform * p)
		
	if path_points.size() < 2:
		set_physics_process(false)
		return
		
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
	if is_instance_valid(path_manager):
		path_manager.release_path(assigned_path)
	var effect_instance = KillEffect.instantiate()
	
	effect_instance.rotation = impact_direction.angle() + PI / 2.0
	effect_instance.global_position = self.global_position
	
	get_parent().add_child(effect_instance)
	
	queue_free()
