extends Node

# 用 @onready 获取节点引用
@onready var player: RigidBody2D = $PlayerBall
@onready var game_ui: Control = $GameUI
@onready var spawner: Node = $EnemySpawner
@onready var crt_effect_rect: ColorRect = $CanvasLayer/ColorRect
@onready var background_effects: AnimatedSprite2D = $BackgroundEffects
@onready var audio_manager: Node = $AudioManager


func _ready() -> void:
	# 连接信号！
	# player 的 speed_updated 信号，连接到 game_ui 的 update_speed_label 函数
	player.speed_updated.connect(game_ui.update_speed_label)
	player.energy_updated.connect(game_ui.update_energy_display)
	player.combo_updated.connect(game_ui.on_combo_updated)
	player.combo_lost.connect(game_ui.on_combo_lost)
	spawner.game_time_updated.connect(game_ui.update_game_timer)
	spawner.score_updated.connect(game_ui.on_score_updated)
	player.combo_updated.connect(on_player_combo_updated)
		# --- 【新增】连接连击中断信号到背景特效 ---
	player.combo_lost.connect(background_effects.play_combo_lost_effect)
	# --- 【新增】连接新的撞墙信号 ---
	player.wall_bounced.connect(audio_manager.on_player_wall_bounced)
	player.wall_bounced.connect(background_effects.play_bounce_effect)



# --- 当玩家连击数更新时，这个函数会被调用 ---
func on_player_combo_updated(combo_count: int):
	if not is_instance_valid(crt_effect_rect) or not crt_effect_rect.material:
		return

	var target_aberration_strength: float = 0.002
	
	if combo_count >= 35:
		target_aberration_strength = 0.02
	elif combo_count >= 20:
		target_aberration_strength = 0.01
	elif combo_count >= 10:
		target_aberration_strength = 0.005
	
	# --- 使用 Tween 实现平滑过渡 ---
	
	# 1. 获取当前的色差值
	var current_aberration = crt_effect_rect.material.get_shader_parameter("chromatic_abberation")
	
	# 2. 创建一个 Tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# 3. 编排动画：
	#    让 crt_effect_rect.material 的 "shader_parameter/chromatic_abberation" 属性，
	#    在 0.3 秒内，从当前值平滑地变化到目标值
	tween.tween_method(
		func(value): crt_effect_rect.material.set_shader_parameter("chromatic_abberation", value),
		current_aberration,
		target_aberration_strength,
		0.3
	)
