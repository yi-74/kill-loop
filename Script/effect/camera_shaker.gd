# ===================================================================
# camera_shaker.gd (V3.0 - 最终丝滑版)
# ===================================================================
extends Camera2D

# --- 可在编辑器中调整的参数 ---
@export var decay_rate: float = 5.0 # 衰减速率，值越大，抖动停止得越快

# --- 内部变量 ---
var shake_strength: float = 0.0 # 当前的抖动强度
var shake_rng = RandomNumberGenerator.new() # 一个随机数生成器

# --- 公开的函数 ---
# 传入一个数值，代表这次冲击的“力度”
func apply_shake(strength: float):
	# 将新的冲击力度，与现有的抖动强度叠加，让抖动可以“累积”
	shake_strength += strength

func _process(delta: float) -> void:
	# 如果当前有抖动强度
	if shake_strength > 0:
		# 1. 随时间，让抖动强度平滑地衰减
		shake_strength = lerp(shake_strength, 0.0, delta * decay_rate)
		
		# 2. 生成一个随机的单位向量，作为抖动的方向
		var random_direction = Vector2.from_angle(shake_rng.randf_range(0, TAU))
		
		# 3. 应用偏移量 = 随机方向 * 当前强度
		offset = random_direction * shake_strength
	else:
		# 确保完全停止后，归位
		shake_strength = 0.0
		offset = Vector2.ZERO
