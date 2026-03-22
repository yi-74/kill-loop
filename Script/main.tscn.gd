extends Node

const BATTLE_BGM = preload("res://assets/Audio/Music/Neon Ghosts.mp3")

var time_scale_before_pause: float = 1.0
var is_paused: bool = false
var is_death_pause_active: bool = false

# 用 @onready 获取节点引用
@onready var crt_effect: ColorRect = GlobalEffects.get_node("CRTEffect")
@onready var player: RigidBody2D = $PlayerBall
@onready var game_ui: Control = $GameUI
@onready var spawner: Node = $EnemySpawner
@onready var crt_effect_rect: ColorRect = $CanvasLayer/ColorRect
@onready var background_effects: AnimatedSprite2D = $BackgroundEffects
@onready var audio_manager: Node = $AudioManager
@onready var bounce_counter_manager: Node = $BounceCounterManager
@onready var pause_menu: CanvasLayer = $PauseMenu



func _ready() -> void:
	#if MusicManager:
		#MusicManager.play()
	reset_crt_shader_parameters()
		
	# 连接信号！
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
	player.wall_bounced.connect(bounce_counter_manager.on_player_wall_bounced)
	player.enemy_killed.connect(bounce_counter_manager.on_player_killed_enemy)
	player.combo_lost.connect(bounce_counter_manager.on_player_combo_lost)
	player.player_died.connect(on_player_died)

	# 告诉全局管理器：平滑过渡到战斗音乐
	MusicManager.crossfade_to(BATTLE_BGM, 1.5)



func _input(event: InputEvent):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = not get_tree().paused


func _process(delta: float):
	# --- 【核心修正】在这里加入状态检查 ---
	# 只有在【不是】死亡暂停的情况下，才根据 paused 状态显示菜单
	if not is_death_pause_active:
		pause_menu.visible = get_tree().paused



func toggle_pause_menu():
	# 1. 直接反转游戏树的暂停状态
	get_tree().paused = not get_tree().paused
	
	# 2. 根据新的暂停状态，来决定是否显示菜单
	pause_menu.visible = get_tree().paused




# --- 当玩家连击数更新时，动态修改 CRT 的色差 ---
func on_player_combo_updated(combo_count: int):
	# 1. 唯一的安全检查（只用新的 crt_effect 变量）
	if not is_instance_valid(crt_effect) or not crt_effect.material:
		print("【警告】找不到 CRT 特效节点或材质！请检查 GlobalEffects！")
		return

	var target_aberration_strength: float = 0.002
	
	if combo_count >= 30:
		target_aberration_strength = 0.02
		print("连击 >= 30: 色差拉满！")
	elif combo_count >= 20:
		target_aberration_strength = 0.012
		print("连击 >= 20: 色差中等！")
	elif combo_count >= 10:
		target_aberration_strength = 0.007
		print("连击 >= 10: 色差初级！")
	
	# 2. 获取当前的色差值（注意：这里去掉了 _rect）
	var current_aberration = crt_effect.material.get_shader_parameter("chromatic_abberation")
	
	# 3. 创建 Tween 并平滑过渡
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# 4. 动态设置参数（注意：这里也去掉了 _rect）
	tween.tween_method(
		func(value): crt_effect.material.set_shader_parameter("chromatic_abberation", value),
		current_aberration,
		target_aberration_strength,
		0.3
	)



func toggle_fullscreen_mode():
	# 我们只做一件事：切换窗口的全屏状态
	# get_window().mode 这个属性，是 Godot 4 中控制窗口模式最直接的方法
	
	if get_window().mode == Window.MODE_FULLSCREEN:
		# 如果当前是全屏，就切换回窗口
		get_window().mode = Window.MODE_WINDOWED
		print("已退出全屏。")
	else:
		# 如果当前不是全屏，就切换到全屏
		get_window().mode = Window.MODE_FULLSCREEN
		print("已进入全屏。")



# --- 【新增】一个专门接收死亡信号的函数 ---
func on_player_died():
	# 当收到玩家死亡的信号时，立刻“上锁”
	is_death_pause_active = true


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
	crt_material.set_shader_parameter("scanline_intensity", 0.05)
	crt_material.set_shader_parameter("barrel_distortion", 0.1)
	crt_material.set_shader_parameter("noise_intensity", 0.2)
	crt_material.set_shader_parameter("scanline_count", 420.0)
	# 3. 【重要】重置子弹时间滤镜的混合度
	#    确保游戏开始时，子弹时间滤-镜是完全关闭的
	crt_material.set_shader_parameter("slow_mo_mix", 0.0)
