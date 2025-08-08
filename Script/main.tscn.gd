extends Node

# 用 @onready 获取节点引用
@onready var player: RigidBody2D = $PlayerBall
@onready var game_ui: Control = $GameUI

func _ready() -> void:
	# 连接信号！
	# player 的 speed_updated 信号，连接到 game_ui 的 update_speed_label 函数
	player.speed_updated.connect(game_ui.update_speed_label)
	player.energy_updated.connect(game_ui.update_energy_display)
	player.combo_updated.connect(game_ui.on_combo_updated)
	player.combo_lost.connect(game_ui.on_combo_lost)
