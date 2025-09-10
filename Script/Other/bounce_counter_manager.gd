extends Node

const BounceCounterScene = preload("res://game/effect/bounce_counter.tscn")

# --- 音效参数 ---
@export_group("Wall Bounce Pitch")
@export var base_pitch: float = 1.2 
@export var pitch_decrement: float = 0.2
@export var combo_lost_pitch: float = 0.5

@onready var wall_bounce_player: AudioStreamPlayer = $WallBouncePlayer
@onready var background_effects: AnimatedSprite2D = get_node("/root/Main_tscn/BackgroundEffects")

# --- 【核心】我们现在管理一个数组，而不是单个变量 ---
var active_counters: Array[Sprite2D] = []


# --- 1. 接收撞墙信号 ---
func on_player_wall_bounced(bounce_count: int, is_combo_lost: bool, impact_position: Vector2):
	if is_instance_valid(background_effects):
		background_effects.play_bounce_effect() # 我们假设 BackgroundEffects 有这个公开函数
	
	# a) 播放音效 (逻辑不变)
	var target_pitch: float
	if is_combo_lost:
		target_pitch = combo_lost_pitch
	else:
		target_pitch = base_pitch - (bounce_count - 1) * pitch_decrement
	wall_bounce_player.pitch_scale = max(target_pitch, 0.1)
	wall_bounce_player.play()
	
  # b) 如果是中断的那一次撞击...
	if is_combo_lost:
		# 首先，让【所有】现存的旧数字都破裂
		for counter in active_counters:
			if is_instance_valid(counter):
				counter.animate_break()
		active_counters.clear()
		
		# 然后，在碰撞点【生成一个新的 '0' 数字】，并让它也播放破裂动画
		var zero_counter = BounceCounterScene.instantiate()
		add_child(zero_counter)
		zero_counter.global_position = impact_position
		zero_counter.animate_break() # animate_break 内部会自动设置 "0.png"
		return

	# c) 如果是普通的撞击，就【只管生成一个新的数字】
	var new_counter = BounceCounterScene.instantiate()
	add_child(new_counter)
	new_counter.global_position = impact_position
	new_counter.animate_spawn(bounce_count)
	
	# 将这个新的数字，添加到我们的管理数组中
	active_counters.append(new_counter)


# --- 2. 接收击杀信号 ---
func on_player_killed_enemy():
	
	# 这个循环的逻辑是正确的
	for counter in active_counters:
		if is_instance_valid(counter):
			# 现在，这个调用会立刻杀死旧动画，并开始播放消失动画
			counter.animate_reset()
			
	# 清空管理数组
	active_counters.clear()


# --- 3. 接收连击中断信号 (来自 lose_combo) ---
#    注意：这个信号和 is_combo_lost=true 的撞墙信号，可能会同时触发
#    我们的逻辑需要能处理这种情况
func on_player_combo_lost():
	# 同样，让【所有】现存的数字都破裂
	for counter in active_counters:
		if is_instance_valid(counter):
			counter.animate_break()
	active_counters.clear()
