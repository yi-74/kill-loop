# floating_text.gd
extends Label

@export var float_speed: float = 50.0
@export var fade_duration: float = 0.5

func setup(score_value: int):
	text = "+" + str(score_value)
	
	# 根据分值动态缩放字体大小 (示例)
	var scale_factor = clamp(score_value / 500.0, 0.8, 1.5)
	scale = Vector2(scale_factor, scale_factor)
	
	# 创建 Tween 动画
	var tween = create_tween()
	tween.set_parallel(true) # 让移动和渐隐同时发生
	
	# 1. 向上飘动
	tween.tween_property(self, "position:y", position.y - 50, fade_duration)
	
	# 2. 渐隐消失
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	
	# 等待动画完成，然后销毁自己
	await tween.finished
	queue_free()
