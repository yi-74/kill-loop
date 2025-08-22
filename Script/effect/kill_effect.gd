# ===================================================================
# kill_effect.gd (V_FINAL - 最终简化版)
# ===================================================================
extends AnimatedSprite2D

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# 在 kill_effect.gd 中，替换旧的 _ready 函数

func _ready() -> void:
	# --- 【核心修正】在这里加入可调的慢放效果 ---

	# 1. 定义一个“慢放程度”的变量 (0.0 到 1.0)
	#    - 0.0 代表完全不受影响
	#    - 1.0 代表完全与子弹时间同步
	#    - 0.6 是一个很好的起点，既有慢放感，又不会太夸张
	var slowdown_factor: float = 0.6 

	# 2. 使用 lerp() 函数，平滑地计算出最终的音高
	#    lerp(from, to, weight) -> 从 from 值向 to 值按 weight 比例插值
	#    我们让音高从 1.0 (正常) 向 time_scale (完全减速) 的方向，移动 slowdown_factor 的距离
	var target_pitch = lerp(1.0, Engine.time_scale, slowdown_factor)
	
	# 3. 应用计算出的新音高
	audio_player.pitch_scale = target_pitch
	
	# --- 后续逻辑保持不变 ---
	play("default")
	audio_player.play()
	
	animation_finished.connect(on_animation_finished)



func on_animation_finished() -> void:
	queue_free()
