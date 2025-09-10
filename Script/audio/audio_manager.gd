# audio_manager.gd
extends Node

# --- 可在编辑器中调整的参数 ---
@export_group("Wall Bounce Pitch")
# 基础音高 (1.0 = 正常)
@export var base_pitch: float = 1.2 
# 每撞一次墙，音高降低多少
@export var pitch_decrement: float = 0.2
# 连击中断时（第四次）的特殊音高
@export var combo_lost_pitch: float = 0.2

@onready var wall_bounce_player: AudioStreamPlayer = $WallBouncePlayer

# --- 公开的函数，给 Main 脚本连接信号 ---
func on_player_wall_bounced(bounce_count: int, is_combo_lost: bool):
	var target_pitch: float

	# 根据是否是“连击中断”的那一次，来决定音高
	if is_combo_lost:
		target_pitch = combo_lost_pitch
	else:
		# 音高 = 基础音高 - (撞墙次数 - 1) * 递减量
		# (bounce_count 从 1 开始，所以要减 1)
		target_pitch = base_pitch - (bounce_count - 1) * pitch_decrement
	
	# 确保音高不会低得离谱
	target_pitch = max(target_pitch, 0.1)
	
	# 设置音高并播放
	wall_bounce_player.pitch_scale = target_pitch
	wall_bounce_player.play()
