extends Node

# 用 @onready 获取节点引用
@onready var player: RigidBody2D = $PlayerBall
@onready var game_ui: Control = $GameUI
@onready var spawner: Node = $EnemySpawner
@onready var crt_effect_rect: ColorRect = $CanvasLayer/ColorRect
@onready var background_effects: AnimatedSprite2D = $BackgroundEffects
@onready var audio_manager: Node = $AudioManager


func _ready() -> void:
	reset_crt_shader_parameters()
	# 连接信号！
	# player 的 speed_updated 信号，连接到 game_ui 的 update_speed_label 函数
	player.speed_updated.connect(game_ui.update_speed_label)
	player.energy_updated.connect(game_ui.update_energy_display)
	player.combo_updated.connect(game_ui.on_combo_updated)
	player.combo_lost.connect(game_ui.on_combo_lost)
	spawner.game_time_updated.connect(game_ui.update_game_timer)
	spawner.score_updated.connect(game_ui.on_score_updated)
	player.combo_updated.connect(on_player_combo_updated)
	player.combo_lost.connect(background_effects.play_combo_lost_effect)
	player.wall_bounced.connect(audio_manager.on_player_wall_bounced)
	player.wall_bounced.connect(background_effects.play_bounce_effect)
	player.energy_bar_1_filled.connect(game_ui.play_bar1_full_animation)
	player.energy_bar_2_filled.connect(game_ui.play_bar2_full_animation)
	player.energy_bar_3_filled.connect(game_ui.play_bar3_full_animation)
	player.launch_failed.connect(game_ui.on_player_launch_failed)
	



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




# --- 一个专门负责重置 CRT 着色器参数的函数 ---
func reset_crt_shader_parameters():
	# 安全检查：确保 CRT 特效节点存在且有材质
	if not is_instance_valid(crt_effect_rect) or not crt_effect_rect.material:
		return

	print("Main: 正在重置 CRT Shader 参数...")
	
	# 获取材质的引用，方便后续调用
	var crt_material = crt_effect_rect.material
	
	# --- 在这里，我们将所有需要重置的参数，都手动设置回它们的默认值 ---
	
	# 1. 重置与连击相关的【色差】
	crt_material.set_shader_parameter("chromatic_abberation", 0.002) # 这是 0-9 连击时的初始值
	
	# 2. 重置您可能手动调整过的其他 CRT 参数
	crt_material.set_shader_parameter("scanline_intensity", 0.03)
	crt_material.set_shader_parameter("barrel_distortion", 0.1)
	crt_material.set_shader_parameter("noise_intensity", 0.002)
	crt_material.set_shader_parameter("scanline_count", 420.0)
	
	# 3. 【重要】重置子弹时间滤镜的混合度
	#    确保游戏开始时，子弹时间滤-镜是完全关闭的
	crt_material.set_shader_parameter("slow_mo_mix", 0.0)
