# ===================================================================
# ui_audio_manager.gd (V_DYNAMIC_CONNECT - 最终动态连接版)
# ===================================================================
extends Node

@onready var hover_player: AudioStreamPlayer = $HoverPlayer
@onready var click_player: AudioStreamPlayer = $ClickPlayer

func _ready() -> void:
	# --- 【核心修正】我们现在监听“场景切换完成”的信号 ---
	get_tree().scene_changed.connect(on_scene_changed)
	
	# 第一次启动时，也手动调用一次，以连接初始场景（主菜单）
	on_scene_changed()

# --- 这是一个全新的函数 ---
func on_scene_changed():
	# 为了避免重复连接，我们最好先断开旧的连接
	# 但为了简化，我们直接重新连接
	
	# 我们用 call_deferred 来确保在调用时，新场景的所有节点都已准备就绪
	call_deferred("connect_all_buttons")

func connect_all_buttons():
	var buttons = get_tree().get_nodes_in_group("buttons")
	print("UIAudioManager: 场景已切换！发现了 ", buttons.size(), " 个按钮，正在连接音效...")
	
	for button in buttons:
		if not button is Button:
			continue
			
		# 【核心修正】在连接前，先检查是否【已经】连接过了，防止重复
		if not button.mouse_entered.is_connected(play_hover_sound):
			button.mouse_entered.connect(play_hover_sound)
		
		if not button.pressed.is_connected(play_click_sound):
			button.pressed.connect(play_click_sound)

func play_hover_sound():
	hover_player.play()

func play_click_sound():
	click_player.play()
