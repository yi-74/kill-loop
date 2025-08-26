# ===================================================================
# kill_effect.gd (V_FINAL - 最终简化版)
# ===================================================================
extends AnimatedSprite2D

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# 在 kill_effect.gd 中，替换旧的 _ready 函数

func _ready() -> void:
	# --- 【核心修正】在这里加入随机音高 ---

	# 1. 定义一个随机范围，比如在正常音高 (1.0) 的上下 15% 之间浮动
	var min_pitch = 0.75
	var max_pitch = 1
	
	# 2. 生成一个随机的音高值
	var random_pitch = randf_range(min_pitch, max_pitch)
	
	# 3. 将最终的音高，与我们之前计算的“子弹时间”音高结合起来
	#    (注意：我们不再直接设置 audio_player.pitch_scale)
	var time_scaled_pitch = lerp(1.0, Engine.time_scale, 0.6) # 这是我们之前的慢放逻辑
	
	#    最终音高 = 慢放后的音高 * 随机偏移
	audio_player.pitch_scale = time_scaled_pitch * random_pitch
	
	# --- 后续逻辑保持不变 ---
	play("default")
	audio_player.play()
	
	animation_finished.connect(on_animation_finished)



func on_animation_finished() -> void:
	queue_free()
