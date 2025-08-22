extends AnimatedSprite2D

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	# 当本节点准备就绪时，立刻开始播放动画
	play("default")
	
	# 【新增】在播放动画的同时，播放音效
	audio_player.play()
	
	# 连接动画播放完成的信号到 "on_animation_finished" 函数
	animation_finished.connect(on_animation_finished)


func on_animation_finished() -> void:
	# 当动画播放完毕后，从场景中移除自己
	queue_free()
