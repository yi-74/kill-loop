extends CanvasLayer

# --- 我们依然使用唯一名称来获取节点，因为这最稳健 ---
@onready var resume_button: Button = %ResumeButton
@onready var tutorial_button: Button = %TutorialButton
@onready var fullscreen_button: Button = %FullscreenButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var tutorial_image: TextureRect = %TutorialImage
@onready var background_animation: AnimatedSprite2D = $BackgroundAnimation

# 我们不再需要 main_script 引用了

func _ready() -> void:
	resume_button.pressed.connect(on_resume_button_pressed)
	tutorial_button.pressed.connect(on_tutorial_button_pressed)
	fullscreen_button.pressed.connect(on_fullscreen_button_pressed)
	main_menu_button.pressed.connect(on_main_menu_button_pressed)
	tutorial_image.gui_input.connect(on_tutorial_image_clicked)
	
		# --- 【新增】在所有数据都准备好后，开始播放背景动画 ---
	if is_instance_valid(background_animation):
		background_animation.play("default")

# 我们不再需要 _input 函数来监听 Esc 了

# --- 按钮回调函数 ---

func on_resume_button_pressed():
	get_tree().paused = false

func on_tutorial_button_pressed():
	tutorial_image.show()

func on_fullscreen_button_pressed():
	# 全屏的逻辑可以自己处理，也可以调用 Main 的，自己处理更简单
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func on_tutorial_image_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		tutorial_image.hide()
