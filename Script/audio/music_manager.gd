extends Node

@onready var track1: AudioStreamPlayer = $Track1
@onready var track2: AudioStreamPlayer = $Track2

var current_track: AudioStreamPlayer
var current_stream: AudioStream

func _ready() -> void:
	# 默认当前轨道是 Track1
	current_track = track1

# --- 核心：播放新音乐并平滑过渡 ---
func crossfade_to(new_stream: AudioStream, fade_duration: float = 1.5) -> void:
	# 如果正在播的已经是这首歌，就什么都不做
	if current_stream == new_stream and current_track.playing:
		return

	current_stream = new_stream
	
	# 找出哪一个是“下一条”轨道
	var next_track = track2 if current_track == track1 else track1
	
	# 准备下一条轨道
	next_track.stream = new_stream
	next_track.volume_db = -80.0 # -80 分贝相当于完全静音
	next_track.play()
	
	# 创建一个 Tween 来同时控制两个音量
	var tween = create_tween()
	tween.set_parallel(true) # 让淡入和淡出同时发生
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 新歌淡入 (从 -80dB 升到 0dB)
	tween.tween_property(next_track, "volume_db", 0.0, fade_duration)
	
	# 老歌淡出 (如果有老歌在播，从 0dB 降到 -80dB)
	if current_track.playing:
		tween.tween_property(current_track, "volume_db", -80.0, fade_duration)
	
	# 动画结束后，把老歌完全停掉
	tween.chain().tween_callback(current_track.stop)
	
	# 交接班：下一条轨道正式成为当前轨道
	current_track = next_track

# --- 瞬间掐停音乐 (用于玩家死亡) ---
func stop_immediately() -> void:
	current_stream = null
	track1.stop()
	track2.stop()
