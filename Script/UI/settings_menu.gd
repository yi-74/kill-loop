# settings_menu.gd
extends Control

# --- 我们依然使用唯一名称来获取节点，因为这最稳健 ---
@onready var back_button: Button = %BackButton
@onready var fullscreen_button: Button = %FullscreenButton
@onready var tutorial_button: Button = %TutorialButton
@onready var english_button: Button = %EnglishButton
@onready var chinese_button: Button = %ChineseButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var tutorial_image: TextureRect = %TutorialImage


func _ready() -> void:
	# 1. 初始化所有 UI 的状态
	fullscreen_button.button_pressed = DataManager.settings.fullscreen
	music_slider.value = DataManager.settings.music_volume
	sfx_slider.value = DataManager.settings.sfx_volume
	back_button.pressed.connect(close_settings)
	
	# 2. 连接所有信号
	back_button.pressed.connect(queue_free) # 最简单的返回，就是销毁自己
	tutorial_button.pressed.connect(on_tutorial_button_pressed)
	tutorial_image.gui_input.connect(on_tutorial_image_clicked)
	fullscreen_button.toggled.connect(on_fullscreen_button_pressed)
	english_button.pressed.connect(func(): set_language("en"))
	chinese_button.pressed.connect(func(): set_language("zh_CN"))
	music_slider.value_changed.connect(on_music_volume_changed)
	sfx_slider.value_changed.connect(on_sfx_volume_changed)


func on_tutorial_button_pressed():
	tutorial_image.show()
	
func on_tutorial_image_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.is_pressed():
		tutorial_image.hide()

func on_fullscreen_button_pressed():
	# 全屏的逻辑可以自己处理，也可以调用 Main 的，自己处理更简单
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func set_language(lang_code: String):
	DataManager.settings.language = lang_code
	DataManager.apply_all_settings()
	DataManager.save_data()
	# 切换语言后，可能需要重启游戏或重新加载场景才能让所有文本生效
	

# --- 【补全】当“音乐音量”滑块的值改变时，这个函数会被调用 ---
func on_music_volume_changed(value: float):
	# 1. 将新的滑块值 (0-100)，更新到 DataManager 的设置中
	DataManager.settings.music_volume = value
	
	# 2. 立刻应用这个新的设置
	#    (我们在这里只应用音量，而不是 apply_all_settings()，效率更高)
	var music_bus_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value / 100.0))
	
	# 3. （可选）当拖动结束时，再保存数据
	#    为了简单，我们可以在 value_changed 时就保存
	DataManager.save_data()


# --- 【补全】当“音效音量”滑块的值改变时，这个函数会被调用 ---
func on_sfx_volume_changed(value: float):
	# 1. 更新 DataManager
	DataManager.settings.sfx_volume = value
	
	# 2. 立刻应用
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value / 100.0))
	
	# 3. 保存
	DataManager.save_data()
	
	# 4. 【可选】为了能立刻听到效果，可以在这里播放一个测试音效
	#    您需要在 SettingsMenu 场景里，也放一个 AudioStreamPlayer
	#    if not test_sfx_player.playing:
	#        test_sfx_player.play()
	
func close_settings():
	# 1. 恢复游戏
	get_tree().paused = false
	# 2. 销毁自己
	queue_free()
