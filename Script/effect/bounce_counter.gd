extends Sprite2D

# --- 预加载数字贴图 ---
const TEXTURES = [
preload("res://assets/SpecialEffects/3210/3.png"), # 对应计数器 = 1
preload("res://assets/SpecialEffects/3210/2.png"), # 对应计数器 = 2
preload("res://assets/SpecialEffects/3210/1.png"), # 对应计数器 = 3
preload("res://assets/SpecialEffects/3210/0.png")  # 对应计数器 = 4 (连击中断)
]
# 注意：请将 "res://textures/..." 替换为您图片的真实路径！

var current_tween: Tween

# --- 1. 生成动画 (撞墙) ---
func animate_spawn(bounce_count: int):
		# --- 【监控点 E】 ---
	print("--- BounceCounter: animate_spawn() 已被调用！---")
	print("E1. 收到的 bounce_count: ", bounce_count)
	# 安全检查：确保次数在我们预期的 1, 2, 3 次范围内
	if bounce_count < 1 or bounce_count > 3:
		print("BounceCounter: 收到了无效的撞墙次数: ", bounce_count)
		return
			
	# --- 【核心修正】正确的数字映射逻辑 ---
	# 计数器 = 1 → 索引 = 0 (3.png)
	# 计数器 = 2 → 索引 = 1 (2.png)
	# 计数器 = 3 → 索引 = 2 (1.png)
	# 这个映射关系，正好是 TEXTURES.size() - bounce_count - 1
	# 我们可以用一个更简单的数组来查表
	
	# 我们直接用一个字典 (Dictionary) 来做映射，最清晰，最不可能出错
	var count_to_texture_index = {
		1: 0, # 第1次撞墙，显示 TEXTURES[0]，即 3.png
		2: 1, # 第2次撞墙，显示 TEXTURES[1]，即 2.png
		3: 2  # 第3次撞墙，显示 TEXTURES[2]，即 1.png
	}
	
	# 检查 bounce_count 是否在我们的映射表里
	if not count_to_texture_index.has(bounce_count):
		return

	var texture_index = count_to_texture_index[bounce_count]
	texture = TEXTURES[texture_index]
	
	current_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	current_tween.set_parallel()
	
	# 动画序列
	current_tween.tween_property(self, "scale", Vector2.ONE, 0.25) # Godot 的 TRANS_BACK 自动处理 1.2 -> 1.0 的回弹
	current_tween.tween_property(self, "modulate:a", 1.0, 0.15) # 透明度变化快一些
	
	show()


# --- 2. 重置动画 (击杀) ---
func animate_reset():
	print("--- 重置动画已被调用！---")
	if is_instance_valid(current_tween): await current_tween.finished # 等待当前动画播完
	
	current_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	current_tween.set_parallel()
	
	current_tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	await current_tween.finished
	queue_free()


# --- 3. 破裂动画 (连击中断) ---
func animate_break():
	print("--- 破裂动画已被调用！---")
	if is_instance_valid(current_tween): await current_tween.finished # 等待当前动画播完
	
	# 连击中断时，强制显示最后一张 "0.png"
	texture = TEXTURES.back()
	
	current_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	current_tween.set_parallel()
	
	current_tween.tween_property(self, "scale", Vector2.ONE * 2.0, 0.25)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	
	await current_tween.finished
	queue_free()
