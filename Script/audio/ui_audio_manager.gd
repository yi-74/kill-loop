# ===================================================================
# ui_audio_manager.gd (V_DYNAMIC_MONITOR - 最终动态监控版)
# ===================================================================
extends Node

@onready var hover_player: AudioStreamPlayer = $HoverPlayer
@onready var click_player: AudioStreamPlayer = $ClickPlayer

func _ready() -> void:
	# --- 【核心修正】使用正确的信号名称 "node_added" ---
	get_tree().node_added.connect(on_node_added)
	
	# 第一次启动时，也手动扫描一次，以连接初始场景的按钮
	call_deferred("scan_existing_buttons")

# --- 这是一个全新的函数，当任何新节点被 add_child() 时，它都会被调用 ---
func on_node_added(node: Node):
	# 我们只关心新加入的节点是不是一个 Button
	if node is Button:
		# 如果是，就只为这【一个】新按钮连接音效
		connect_button_sounds(node)

# --- 这是一个在启动时，用来扫描所有已存在按钮的函数 ---
func scan_existing_buttons():
	var buttons = get_tree().get_nodes_in_group("buttons")
	print("UIAudioManager: 初始扫描，发现了 ", buttons.size(), " 个已存在的按钮。")
	for button in buttons:
		if button is Button:
			connect_button_sounds(button)

# --- 这是一个被上面两个函数共同调用的、专门负责连接的函数 ---
func connect_button_sounds(button: Button):
	# 【重要】我们只为在 "buttons" 分组里的按钮添加音效
	if not button.is_in_group("buttons"):
		return

	# 在连接前，先检查是否已经连接过了，防止重复
	if not button.mouse_entered.is_connected(play_hover_sound):
		button.mouse_entered.connect(play_hover_sound)
	
	if not button.pressed.is_connected(play_click_sound):
		button.pressed.connect(play_click_sound)

# --- 播放函数 (保持不变) ---
func play_hover_sound():
	hover_player.play()

func play_click_sound():
	click_player.play()
