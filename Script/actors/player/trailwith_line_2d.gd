
# ===================================================================
# TrailWithLine2D.gd (V_FINAL_SMOOTH_RELIABLE - 可靠平滑版)
# ===================================================================
extends Line2D

@export var point_count: int = 15
@export var min_distance: float = 10.0
@export var is_enabled: bool = true

var parent_node: Node2D
var last_point_position: Vector2 = Vector2.INF # 使用无穷大来确保第一帧能画点

func _ready() -> void:
	if get_parent() is Node2D:
		parent_node = get_parent()
	else:
		is_enabled = false
		push_error("Trail's parent is not a Node2D. Disabling.")

# 我们仍然使用 _physics_process，但配合物理插值，它会变得平滑
func _physics_process(delta: float) -> void:
	# 安全检查
	if not is_enabled or not is_instance_valid(parent_node):
		if get_point_count() > 0: remove_point(get_point_count() - 1)
		return

	# 强制将自身位置重置到世界原点，以解决“双重偏移”
	global_position = Vector2.ZERO
	global_rotation = 0

	var parent_pos = parent_node.global_position
	
	# 只有当移动距离足够时，才添加新点
	if parent_pos.distance_to(last_point_position) > min_distance:
		add_point(parent_pos)
		last_point_position = parent_pos
		
		# 从尾部移除多余的点
		while get_point_count() > point_count:
			remove_point(0)
