# breakthrough_effect.gd
extends Label

# 这个函数将由 GameUI 在创建实例后调用
func animate(score_text: String):
	# 1. 设置要显示的文本（即打破记录的那个分数）
	text = score_text
	
	# 2. 创建一个 Tween 来执行所有动画
	var tween = create_tween()
	tween.set_parallel() # 让放大和渐隐同时发生
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT) # 使用平滑的曲线

	# 3. 【放大动画】
	#    在 0.8 秒内，将 scale 从 1.0 放大到 1.5 倍
	tween.tween_property(self, "scale", Vector2.ONE * 1.5, 0.8)
	
	# 4. 【渐隐动画】
	#    在同样的 0.8 秒内，将 modulate:a (透明度) 从 1.0 变为 0.0
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	
	# 5. 等待动画完成，然后销毁自己
	await tween.finished
	queue_free()
