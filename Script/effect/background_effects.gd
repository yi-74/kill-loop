# background_effects.gd
extends AnimatedSprite2D

func _ready() -> void:
	# 游戏开始时，播放默认的静态背景
	play("idle")
	# 连接动画播放完成的信号
	animation_finished.connect(on_animation_finished)

# --- 公开的函数，给 Main 脚本调用 ---
func play_bounce_effect():
	# 播放撞墙动画
	play("bounce")

func play_combo_lost_effect():
	# 播放连击中断动画
	play("combo_lost")

# 当任何一个【非循环】动画播放完毕后，这个函数会被调用
func on_animation_finished():
	# 动画结束后，切回默认的静态背景
	play("idle")
