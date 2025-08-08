# enemy_normal.gd
extends RigidBody2D


# 在脚本顶部预加载特效场景
const KillEffect = preload("res://game/effect/kill_effect.tscn")

# ... (您现有的 _ready 等函数) ...
func _ready():
	# 在编辑器右侧的 "节点" -> "分组" 面板中把它加入 "enemy" 分组
	# 这样 PlayerBall 脚本中的 is_in_group("enemy") 才能生效
	pass


# --- 让 die() 函数可以接收一个方向参数 ---
func die(impact_direction: Vector2) -> void:
	var effect_instance = KillEffect.instantiate()
	
	# --- 计算并设置旋转 ---
	# Vector2 有一个 angle() 方法，可以获取向量的角度（弧度制）
	# 我们希望特效的“朝上”方向（通常是Y轴负方向）对准撞击方向
	# 所以我们需要加上 PI/2 (90度) 来校准
	effect_instance.rotation = impact_direction.angle() + PI / 2.0
	
	# 设置位置
	effect_instance.global_position = self.global_position
	
	# 添加到场景
	get_parent().add_child(effect_instance)
	
	# 自己消失
	queue_free()
