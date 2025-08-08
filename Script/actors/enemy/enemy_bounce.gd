# enemy_bounce.gd
extends RigidBody2D

func _ready():
	# 同样加入 "enemy" 分组, 这样玩家才能和它交互
	# 同样设置 contact_monitor = true 来检测碰撞
	contact_monitor = true
	max_contacts_reported = 5

# 弹射敌人自己不会被玩家直接撞死, 所以没有 die() 函数
# 但它需要检测自己撞到了谁
# enemy_bounce.gd 的调试版本

func _on_body_entered(body):
	print("--- 弹射敌人碰撞检测开始 ---")
	print("1. 撞到的对象是: ", body.name)

	# 检查第一个条件：对象是否在 "enemy" 分组
	if body.is_in_group("enemy"):
		print("2. ✔️ 分组检查通过：撞到的对象在 'enemy' 分组里。")

		# 检查第二个条件：对象不是它自己
		if not body == self:
			print("3. ✔️ 自我检查通过：撞到的不是弹射敌人自己。")

			# 检查第三个条件：对象有没有 "die" 方法
			if body.has_method("die"):
				print("4. ✔️ 方法检查通过：对象有 'die' 方法。")
				print("所有条件满足！执行连锁击杀！")
				body.die()
				self.die_in_chain_reaction()
			else:
				print("4. ❌ 方法检查失败：撞到的对象没有 'die' 方法！")
		else:
			print("3. ❌ 自我检查失败：撞到的是弹-射敌人自己。")
	else:
		print("2. ❌ 分组检查失败：撞到的对象不在 'enemy' 分组里！")
	
	print("--- 检测结束 ---")

# 创建一个专用于连锁反应的死亡函数, 以便未来添加不同特效
func die_in_chain_reaction():
	# 在这里可以添加特殊的连锁死亡特效
	queue_free()
