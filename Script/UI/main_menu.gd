extends Control

# --- 节点引用 ---
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var fullscreen_button: Button = $VBoxContainer/FullscreenButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var tutorial_image: TextureRect = $TutorialImage

# --- 内部状态 ---
var is_showing_tutorial: bool = false

func _ready() -> void:
	# --- 连接所有按钮的 "pressed" 信号 ---
	start_button.pressed.connect(on_start_button_pressed)
	fullscreen_button.pressed.connect(on_fullscreen_button_pressed)
	quit_button.pressed.connect(on_quit_button_pressed)
	
	# 游戏开始时，让教程图片可以接收输入
	tutorial_image.gui_input.connect(on_tutorial_image_clicked)

# --- 按下“开始游戏”按钮 ---
func on_start_button_pressed():
	# 检查 DataManager 中是否已经有“玩过”的记录
	if not DataManager.has_played_before:
		# 如果是第一次玩，就显示教程
		tutorial_image.show()
		is_showing_tutorial = true
		# 并且在 DataManager 中记录下“已经玩过了”
		DataManager.set_played_before()
	else:
		# 如果不是第一次玩，就直接开始游戏
		start_game()

# --- 按下“设置全屏”按钮 ---
func on_fullscreen_button_pressed():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# --- 按下“退出游戏”按钮 ---
func on_quit_button_pressed():
	get_tree().quit()

# --- 当教程图片被点击时 ---
func on_tutorial_image_clicked(event: InputEvent):
	# 只要有任何鼠标点击事件，就关闭教程并开始游戏
	if event is InputEventMouseButton and event.is_pressed():
		start_game()

# --- 开始游戏的统一函数 ---
func start_game():
	# 切换到您的主游戏场景
	get_tree().change_scene_to_file("res://Scene/Main.tscn.tscn")
