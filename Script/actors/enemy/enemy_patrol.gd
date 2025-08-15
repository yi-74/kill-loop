extends RigidBody2D

# --- 可在编辑器中调整的参数 ---
@export var move_speed: float = 150.0    # 巡逻速度
@export var turn_rate: float = 5.0       # 转向平滑度

# --- 节点引用 ---
@onready var path: Path2D = $Path2D # 获取路径节点

# --- 内部变量 ---
var path_points: PackedVector2Array # 用来存储路径上的所有点
var current_target_index: int = 1  # 当前的目标点索引
var move_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 获取 Path2D 中曲线的所有顶点
	path_points = path.curve.get_baked_points()
	
	# 安全检查：如果路径上的点少于2个，就禁用移动
	if path_points.size() < 2:
		set_physics_process(false) # 关闭 _physics_process 函数
		return
		
	# 将自己的初始位置，设置为路径的第一个点的位置
	# 注意：Path2D 的点是局部坐标，所以我们直接设置 position
	position = path_points[0]


func _physics_process(delta: float) -> void:
	# 1. 获取当前的目标点
	var target_position = path_points[current_target_index]
	
	# 2. 计算朝向目标点的方向
	move_direction = (target_position - position).normalized()
	
	# 3. 朝目标方向移动
	linear_velocity = move_direction * move_speed
	
	# 4. 平滑地旋转朝向
	var target_angle = move_direction.angle()
	rotation = lerp_angle(rotation, target_angle + PI/2.0, delta * turn_rate)
	
	# 5. 检查是否已接近目标点
	if position.distance_to(target_position) < 10.0: # 10像素的容差
		# 如果接近了，就更新目标点到下一个
		current_target_index += 1
		
		# 如果已经到达路径的终点，就反向
		if current_target_index >= path_points.size():
			# 反转路径点的顺序
			path_points.reverse()
			# 目标重置为第二个点（因为第一个点已经是当前位置了）
			current_target_index = 1


# --- 死亡逻辑 (与 EnemyNormal 完全一样) ---
const KillEffect = preload("res://game/effect/kill_effect.tscn")

func die(impact_direction: Vector2) -> void:
	var effect_instance = KillEffect.instantiate()
	
	effect_instance.rotation = impact_direction.angle() + PI / 2.0
	effect_instance.global_position = self.global_position
	
	get_parent().add_child(effect_instance)
	
	queue_free()
