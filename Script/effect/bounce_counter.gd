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
var is_disappearing: bool = false # 【新增】状态锁，防止在消失时被再次触发


# --- 1. 生成动画 (撞墙) ---
func animate_spawn(bounce_count: int):
	# 【新增】如果正在消失，就忽略所有新的生成指令
	if is_disappearing:
		return
		
	# 安全检查和贴图映射 (与之前相同)
	var count_to_texture_index = { 1: 0, 2: 1, 3: 2 }
	if not count_to_texture_index.has(bounce_count): return
	texture = TEXTURES[count_to_texture_index[bounce_count]]
	
	# 杀死旧动画，确保状态干净
	if is_instance_valid(current_tween): current_tween.kill()
	
	# 重置初始状态
	scale = Vector2.ONE * 0.6
	modulate.a = 0.0
	show() # 确保可见
	
	current_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	current_tween.set_parallel()
	
	# 【核心修正】手动编排一个更可靠的“弹出”动画
	var anim_tween_seq = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# a) 先放大到 1.2 倍
	anim_tween_seq.tween_property(self, "scale", Vector2.ONE * 1.2, 0.3)
	# b) 再恢复到 1.0 倍
	anim_tween_seq.tween_property(self, "scale", Vector2.ONE, 0.5)
	
	# 透明度动画
	current_tween.tween_property(self, "modulate:a", 1.0, 0.15)


# --- 2. 重置动画 (击杀) ---
func animate_reset():
	# 【核心修正】不再等待旧动画，而是直接杀死它
	if is_instance_valid(current_tween):
		current_tween.kill()

	is_disappearing = true # 标记为“正在消失”
	
	current_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	current_tween.set_parallel()
	
	current_tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	# 我们不再在函数内部等待，而是让 Tween 自己处理销毁
	current_tween.finished.connect(queue_free)


# --- 3. 破裂动画 (连击中断) ---
# --- 3. 破裂动画 (连击中断) ---
func animate_break():
	# --- 【核心修正】与 animate_reset() 保持完全一致的健壮性 ---

	# a) 立即杀死任何正在运行的旧动画
	if is_instance_valid(current_tween):
		current_tween.kill()

	# b) 设置“正在消失”状态锁
	is_disappearing = true
	
	# c) 强制显示 "0.png" 贴图
	texture = TEXTURES.back()
	show() # 确保在播放动画前是可见的
	
	# d) 创建新的“破裂”动画 Tween
	current_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	current_tween.set_parallel()
	
	# e) 编排动画
	current_tween.tween_property(self, "scale", Vector2.ONE * 2.0, 0.25)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	
	# f) 【核心】使用信号，在动画播放完毕后，再安全地销毁自己
	current_tween.finished.connect(queue_free)
