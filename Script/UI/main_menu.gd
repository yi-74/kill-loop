extends Control

const DataStatsScene = preload("res://game/UI/data_stats.tscn")

# --- 节点引用 ---
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var stats_button: Button = $VBoxContainer/StatsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var tutorial_image: TextureRect = $TutorialImage
@onready var background_effects: AnimatedSprite2D = $BackgroundEffects
@onready var settings_menu: Control = $SettingsMenu

# --- 内部状态 ---
var is_showing_tutorial: bool = false


func _ready() -> void:
	# --- 连接所有按钮的 "pressed" 信号 ---
	start_button.pressed.connect(on_start_button_pressed)
	settings_button.pressed.connect(on_settings_button_pressed)
	stats_button.pressed.connect(on_stats_button_pressed)
	quit_button.pressed.connect(on_quit_button_pressed)
	
	
	# 游戏开始时，让教程图片可以接收输入
	tutorial_image.gui_input.connect(on_tutorial_image_clicked)


# --- 按下“开始游戏”按钮 (V2.0 - 基于分数判断) ---
func on_start_button_pressed():
	# --- 【核心修正】我们现在直接检查 DataManager 里的最高分 ---
	if DataManager.high_score < 1000:
		# 如果最高分小于 1000，就认为ta是“新玩家”，显示教程
		print("MainMenu: 最高分低于1000，判定为新玩家，显示教程。")
		tutorial_image.show()
		# is_showing_tutorial = true # 这个状态变量可能不再需要，但可以保留
	else:
		# 如果最高分大于等于 1000，就直接开始游戏
		print("MainMenu: 最高分已达到，判定为老玩家，直接开始游戏。")
		start_game()


# --- 【新增】一个全新的函数，用来打开设置菜单 ---
func on_settings_button_pressed():
	# --- 【核心修正】我们不再创建，而是直接显示 ---
	settings_menu.show()


# --- 【新增】一个全新的函数，用来打开数据统计页面 ---
func on_stats_button_pressed():
	# 1. 创建数据统计页面的实例
	var stats_menu_instance = DataStatsScene.instantiate()
	
	# 2. 将它作为子节点，添加到当前场景中
	#    这会让它像一个“弹窗”一样，显示在主菜单之上
	add_child(stats_menu_instance)
	
	print("主菜单：已打开数据统计页面。")


# --- 按下“退出游戏”按钮 ---
func on_quit_button_pressed():
	get_tree().quit()

# --- 当教程图片被点击时 ---
func on_tutorial_image_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		# 【核心】让教程图片的点击，也走带有转场动画的流程
		start_game()

# --- 开始游戏的统一函数 ---
func start_game():
	# 安全检查
	if not is_instance_valid(background_effects):
		# 如果找不到特效，就直接切换场景
		get_tree().change_scene_to_file("res://Scene/Main.tscn.tscn")
		return

	# --- 【核心】转场动画逻辑 ---
	
	# 1. 禁用所有按钮，防止玩家在转场时重复点击
	start_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true
	
	# 2. 播放“连击中断”动画
	background_effects.play("combo_lost") # 我们假设这个动画名叫 "combo_lost"
	
	# 3. 等待这个动画播放【完毕】
	await background_effects.animation_finished
	
	# 4. 动画播放完毕后，再执行场景切换
	get_tree().change_scene_to_file("res://Scene/Main.tscn.tscn")
