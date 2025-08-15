# ===================================================================
# EnemyTracker.gd - 追踪敌人脚本
# ===================================================================
extends RigidBody2D

# --- 可在编辑器中调整的参数 ---
@export var move_speed: float = 200.0     # 敌人的移动速度
@export var turn_rate: float = 5.0       # 敌人转向的平滑度，值越大转得越快

# --- 节点引用 ---
@onready var update_timer: Timer = $UpdateTimer # 获取计时器节点

# --- 内部变量 ---
var player: Node2D = null # 用来存储玩家的引用
var move_direction: Vector2 = Vector2.DOWN # 初始移动方向


func _ready() -> void:
	# 尝试在场景中找到玩家节点
	# 注意：这个方法假设 PlayerBall 节点的名字就是 "PlayerBall"
	# 如果您的主场景结构复杂，可能需要用更稳健的方法（比如分组或单例）来获取
	player = get_tree().get_root().find_child("PlayerBall", true, false)
	
	# 确保计时器在游戏开始时就启动
	update_timer.start()


func _physics_process(delta: float) -> void:
	# --- 1. 持续朝目标方向移动 ---
	# 使用 move_and_collide 来移动，它能正确地处理与墙壁的碰撞
	# move_and_collide(move_direction * move_speed * delta)
	# 为了更好的物理效果，我们直接设置速度，让它有“惯性”
	linear_velocity = move_direction * move_speed

	# --- 2. 平滑地旋转朝向 ---
	# 计算当前朝向和目标朝向之间的角度差，然后平滑地插值
	var target_angle = move_direction.angle()
	# 同样，根据您美术素材的朝向，可能需要加上 PI/2 (90度)
	rotation = lerp_angle(rotation, target_angle + PI/2.0, delta * turn_rate)


# --- 计时器超时后，这个函数会被自动调用 ---
func _on_update_timer_timeout():
	# 安全检查：如果找不到玩家，就原地不动
	if not is_instance_valid(player):
		move_direction = Vector2.ZERO
		return
		
	# 计算从敌人指向玩家的新的方向向量
	var direction_to_player = (player.global_position - self.global_position).normalized()
	
	# 更新移动方向
	move_direction = direction_to_player
	
	# 计时器会自动重复，所以不需要手动再 start()


# --- 死亡逻辑 (与 EnemyNormal 完全一样) ---
const KillEffect = preload("res://game/effect/kill_effect.tscn")

func die(impact_direction: Vector2) -> void:
	var effect_instance = KillEffect.instantiate()
	
	effect_instance.rotation = impact_direction.angle() + PI / 2.0
	effect_instance.global_position = self.global_position
	
	get_parent().add_child(effect_instance)
	
	queue_free()
