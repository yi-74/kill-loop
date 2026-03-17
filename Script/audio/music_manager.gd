# ===================================================================
# music_manager.gd (完美平滑过渡修复版)
# ===================================================================
extends Node

@onready var track1: AudioStreamPlayer = $Track1
@onready var track2: AudioStreamPlayer = $Track2

var current_track: AudioStreamPlayer
var current_stream: AudioStream

# --- 【新增】用来存储当前正在执行的过渡动画 ---
var fade_tween: Tween

func _ready() -> void:
	current_track = track1

func crossfade_to(new_stream: AudioStream, fade_duration: float = 1.5) -> void:
	# 如果正在播的已经是这首歌，就什么都不做
	if current_stream == new_stream and current_track.playing:
		return

	# -------------------------------------------------------------
	# --- 【核心修复】如果上一次的切歌动画还没播完，立刻杀死它！ ---
	# -------------------------------------------------------------
	if is_instance_valid(fade_tween) and fade_tween.is_running():
		fade_tween.kill()

	current_stream = new_stream
	
	# 找出哪一个是“下一条”轨道
	var next_track = track2 if current_track == track1 else track1
	
	# 准备下一条轨道
	next_track.stream = new_stream
	next_track.volume_db = -80.0 
	next_track.play()
	
	# 将新的 Tween 赋值给我们的全局变量，方便下次检查
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 新歌淡入
	fade_tween.tween_property(next_track, "volume_db", 0.0, fade_duration)
	
	# 老歌淡出
	if current_track.playing:
		fade_tween.tween_property(current_track, "volume_db", -80.0, fade_duration)
	
	# 动画结束后停止老歌
	fade_tween.chain().tween_callback(current_track.stop)
	
	# 交接班
	current_track = next_track

# --- 瞬间掐停音乐 (用于玩家死亡) ---
func stop_immediately() -> void:
	# 停止时，也要把正在进行的过渡动画掐掉
	if is_instance_valid(fade_tween) and fade_tween.is_running():
		fade_tween.kill()
		
	current_stream = null
	track1.stop()
	track2.stop()
