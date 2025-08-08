extends TextureProgressBar

# 一个函数，用来接收新的能量值 (0-100) 并更新进度条
func update_progress(new_value: float):
	value = new_value
