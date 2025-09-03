extends Node

const BounceCounterScene = preload("res://game/effect/bounce_counter.tscn")

var active_counter: Sprite2D = null

# --- 接收撞墙信号 ---
func on_player_wall_bounced(bounce_count: int, is_combo_lost: bool, impact_position: Vector2):
	# --- 【监控点 A】 ---
	print("--- Manager: 收到【撞墙】信号 ---")
	print("A1. 撞墙次数: ", bounce_count, " | 是否中断: ", is_combo_lost)
	# 如果是中断的那一次撞击
	if is_combo_lost:
		if is_instance_valid(active_counter):
			active_counter.animate_break()
		active_counter = null # 清空引用
		return

	# --- 如果是普通的撞击 ---
	# 如果已经有一个计数器，先让它消失
	if is_instance_valid(active_counter):
		active_counter.animate_reset()
		
	# 创建一个新的计数器实例
	active_counter = BounceCounterScene.instantiate()
	add_child(active_counter)
	
	# 【核心】获取碰撞点位置 (我们需要 PlayerBall 广播这个信息)
	# 我们先用一个临时位置
	# 【核心】我们将在这里直接设置位置，而不是在 BounceCounter 内部
	active_counter.global_position = impact_position

	print("Manager: 已将新的 BounceCounter 位置设置为: ", active_counter.global_position)
	# --- 【监控点 B】 ---
	print("B1. 已创建新的 BounceCounter 实例。")
	print("B2. 准备调用 animate_spawn，传入 bounce_count: ", bounce_count)
	
	active_counter.animate_spawn(bounce_count)

# --- 接收击杀信号 ---
func on_player_killed_enemy():
	if is_instance_valid(active_counter):
		active_counter.animate_reset()
	active_counter = null

# --- 接收连击中断信号 (来自 lose_combo) ---
func on_player_combo_lost():
	if is_instance_valid(active_counter):
		active_counter.animate_break()
	active_counter = null
