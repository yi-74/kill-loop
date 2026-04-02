extends Control

@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var combo_lost_anim: AnimationPlayer = $ComboLostAnimationPlayer
@onready var energy_bar_1: TextureProgressBar = $BoxContainer/EnergyBar
@onready var energy_bar_2: TextureProgressBar = $BoxContainer/EnergyBar2
@onready var energy_bar_3: TextureProgressBar = $BoxContainer/EnergyBar3
@onready var effect_bar1_full: AnimatedSprite2D = $BoxContainer/EnergyBar1_FullEffect
@onready var effect_bar2_full: AnimatedSprite2D = $BoxContainer/EnergyBar2_FullEffect
@onready var effect_bar3_full: AnimatedSprite2D = $BoxContainer/EnergyBar3_FullEffect
@onready var launch_fail_effect: AnimatedSprite2D = $BoxContainer/LaunchFailEffect
@onready var speed_value_label: Label = $HBoxContainer/SpeedValue
# 注意：为了能正确获取，您可能需要手动给场景树里的三个能量条改名
@onready var combo_label: Label = $ComboLabel
@onready var game_timer_label: Label = $GameTimerLabel
@onready var danger_flash: ColorRect = $DangerFlash # 前提是您已经在 GameUI 下建了这个节点

var was_speed_safe: bool = false # 记录上一帧的速度状态
var danger_tween: Tween # 用来管理动画，防止连续撞墙时动画冲突
var is_high_score_broken: bool = false
var displayed_score: float = 0.0
var combo_label_initial_scale: Vector2 = Vector2.ONE
var combo_tween: Tween
var combo_color_tween: Tween # 用于控制连击中断时的颜色动画


func _ready():
	# 游戏开始时，显示历史最高分
	high_score_label.text = "High: " + str(DataManager.high_score)
	
	if is_instance_valid(combo_label):
		combo_label_initial_scale = combo_label.scale
		
			# --- 【新增】连接三个特效的动画完成信号 ---
	if is_instance_valid(effect_bar1_full):
		effect_bar1_full.animation_finished.connect(func(): effect_bar1_full.hide())
		
	if is_instance_valid(effect_bar2_full):
		effect_bar2_full.animation_finished.connect(func(): effect_bar2_full.hide())
		
	if is_instance_valid(effect_bar3_full):
		effect_bar3_full.animation_finished.connect(func(): effect_bar3_full.hide())
		
	if is_instance_valid(launch_fail_effect):
		launch_fail_effect.animation_finished.connect(func(): launch_fail_effect.hide())
		
	if is_instance_valid(danger_flash):
		danger_flash.modulate.a = 0.0


func _process(delta: float) -> void:
	# --- 【新增】在每一帧，都用 displayed_score 的整数部分来更新文本 ---
	score_label.text = str(int(displayed_score))



func on_score_updated(new_score: int):
	# 1. 创建一个 Tween 动画控制器
	var tween = create_tween()
	# 使用一个“缓出”曲线，让数字滚动在结束时有一个漂亮的减速效果
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# 2. 【核心】编排动画：
	#    让本脚本(self)的 "displayed_score" 属性，
	#    在 0.5 秒内（可调），从它当前的值，平滑地变化到新的目标分数 new_score
	tween.tween_property(self, "displayed_score", float(new_score), 0.5)

	# 3. 获取最新的历史最高分，并更新显示 (这部分逻辑保持不变)
	var current_high_score = DataManager.high_score
	high_score_label.text = "High: " + str(current_high_score)
	
	# 4. 根据【最终分数】来决定颜色 (而不是中间值)
	if new_score >= current_high_score:
		score_label.add_theme_color_override("font_color", Color("00ffff")) # 青色
	else:
		# 如果新的一局开始，分数低于最高分，需要把颜色恢复成红色
		# 我们需要确保在游戏重启时，颜色能被重置
		score_label.add_theme_color_override("font_color", Color("ff3b30")) # 红色



func update_game_timer(new_time_float: float) -> void:
	# --- 1. 手动截断，保留两位小数 ---
	# a) 将秒数乘以 100，例如 83.518 -> 8351.8
	var multiplied = new_time_float * 100.0
	# b) 取整数部分，砍掉所有多余的小数，得到 8351
	var truncated_int = int(multiplied)
	# c) 再除以 100.0，得到精确截断后的浮点数 83.51
	var truncated_float = truncated_int / 100.0
	
	# --- 2. 使用字符串格式化，强制显示两位小数 ---
	#    "%.2f" 会强制让数字以保留两位小数的形式显示
	#    如果数字本身只有一位小数（如 2.6），它会自动在末尾补一个 0，变成 "2.60"
	#    如果数字是整数（如 27.0），它会自动补上 ".00"，变成 "27.00"
	var formatted_string = "%.2f" % truncated_float
	
	# 3. 更新 Label 的文本
	game_timer_label.text = formatted_string



func update_speed_label(new_speed: float) -> void:
	# 1. 基础数值计算 (保持不变)
	var scaled_speed = new_speed / 10.0
	var final_speed_int = int(scaled_speed)
	
	# 2. 【核心修改】现在只更新数字 Label 的文本
	speed_value_label.text = str(final_speed_int)
	
	# --- 3. 计算“危险渐变”动画 (2000 -> 1500) ---
	# 计算当前速度在 2000 到 1500 之间的“危险进度” (0.0 到 1.0)
	# 速度 >= 2000 时，progress = 0.0
	# 速度 <= 1500 时，progress = 1.0
	var progress = clamp((2000.0 - new_speed) / 500.0, 0.0, 1.0)
	
	# 【完美实现您的需求】使用 3 次方公式，制造“越靠近 1500 效果越大”的曲线
	# progress 如果是 0.5 (即 1750)，0.5 的 3次方只有 0.125，变化很微弱
	# progress 如果是 0.9 (即 1550)，0.9 的 3次方是 0.729，变化急剧加深！
	var curve_progress = pow(progress, 3.0)
	
	# a) 颜色插值：从纯白平滑过渡到危险红
	var safe_color = Color("ffffff")
	var danger_color = Color("ff3b30")
	var current_color = safe_color.lerp(danger_color, curve_progress)
	speed_value_label.add_theme_color_override("font_color", current_color)
	
	speed_value_label.add_theme_color_override("font_color", current_color)
	
	# b) 动态计算轴心点，破解容器限制！
	var current_scale = lerp(1.0, 1.5, curve_progress)
	
	# 强制将“图钉”钉在 Label 的：X=0(最左边), Y=高度的一半(垂直正中间)
	speed_value_label.pivot_offset = Vector2(0, speed_value_label.size.y / 2.0)
	
	# 现在再应用缩放，它就会完美地向右侧和上下均匀膨胀了！
	speed_value_label.scale = Vector2(current_scale, current_scale)
	# --- 4. 原来的边缘闪红逻辑
	var is_currently_safe = (new_speed >= 1500.0)
	
	if was_speed_safe and not is_currently_safe:
		play_danger_flash()
		
	was_speed_safe = is_currently_safe



# 一个函数，用来接收一个总能量值 (0-300)，并更新所有能量条
func update_energy_display(total_energy: float):
	# 将总能量分配到三个能量条上
	energy_bar_1.value = clamp(total_energy, 0, 100)
	energy_bar_2.value = clamp(total_energy - 100, 0, 100)
	energy_bar_3.value = clamp(total_energy - 200, 0, 100)



func play_bar1_full_animation():
	if is_instance_valid(effect_bar1_full):
		effect_bar1_full.show() # 先让它可见
		effect_bar1_full.play("play_full_effect") # 播放动画 (假设动画名叫 "default")

func play_bar2_full_animation():
	if is_instance_valid(effect_bar2_full):
		effect_bar2_full.show()
		effect_bar2_full.play("play_full_effect")

func play_bar3_full_animation():
	if is_instance_valid(effect_bar3_full):
		effect_bar3_full.show()
		effect_bar3_full.play("play_full_effect")



# --- 创建新的接收函数 ---
func on_player_launch_failed():
	if is_instance_valid(launch_fail_effect):
		launch_fail_effect.show()
		launch_fail_effect.play("flash")



# --- 新增：接收连击更新的函数 ---
func on_combo_updated(combo_count: int):
	# 无论 combo_count 是多少，都先更新文本
	combo_label.text = str(combo_count)
	
	# 然后，根据 combo_count 的值，来决定播放哪种动画
	if combo_count > 0:
		# 如果是增加连击，就播放“放大”动画
		play_combo_bump_animation()
	else:
		# 如果是连击中断（归零），就播放“缩小”动画
		play_combo_reset_animation()



# --- 动画一：增加连击时的“放大弹跳” ---
func play_combo_bump_animation():
	if not is_instance_valid(combo_label): return

	if is_instance_valid(combo_tween): combo_tween.kill()
	combo_label.scale = combo_label_initial_scale

	combo_tween = create_tween()
	# 【手感调校】使用更有弹性的 ELASTIC 曲线
	combo_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# 动画序列：
	# a) 用 0.3 秒放大到 1.5 倍
	combo_tween.tween_property(combo_label, "scale", combo_label_initial_scale * 1.3, 0.5)
	# b) 再用 0.2 秒恢复5
	combo_tween.tween_property(combo_label, "scale", combo_label_initial_scale, 0.5)



# --- 动画二：连击中断时的“缩小抖动” ---
func play_combo_reset_animation():
	if not is_instance_valid(combo_label): return

	if is_instance_valid(combo_tween): combo_tween.kill()
	combo_label.scale = combo_label_initial_scale
	
	combo_tween = create_tween()
	# 【手感调校】使用更平滑的 SINE 或 QUART 曲线
	combo_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# 动画序列：
	# a) 用 0.2 秒，缩小到 0.8 倍
	combo_tween.tween_property(combo_label, "scale", combo_label_initial_scale * 0.7, 0.4)
	# b) 再用 0.4 秒，带有弹性地恢复到原始大小
	#    我们在这里切换一次缓动曲线，让回弹更有力
	combo_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	combo_tween.tween_property(combo_label, "scale", combo_label_initial_scale, 0.5)



# --- 新增：接收连击中断的函数 ---
func on_combo_lost():
	# 播放 "Combo Lost" 动画
	#combo_lost_anim.play("show_and_fade")
	
	# 播放连击中断的颜色高亮效果
	play_combo_lost_color_effect()
	return


# --- 新增：播放连击中断时标签颜色变化的动画 ---
func play_combo_lost_color_effect():
	# 安全检查，确保 ComboLabel 存在
	if not is_instance_valid(combo_label):
		return

	# 如果上一个颜色动画还在播放，先停止它，防止动画冲突
	if is_instance_valid(combo_color_tween):
		combo_color_tween.kill()

	# 创建一个新的 Tween 动画实例
	combo_color_tween = create_tween()
	# 设置动画曲线，使其末尾有缓动效果，看起来更自然
	combo_color_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# 步骤1: 立即将标签的颜色“混合模式”设置为红色。
	# self_modulate 会将节点自身的颜色与这个颜色相乘，所以设为红色就会变红。
	combo_label.self_modulate = Color.RED
	
	# 步骤2: 创建动画，在 1 秒内，将颜色混合模式平滑地恢复为白色。
	# Color.WHITE (即 Color(1,1,1,1)) 在这里的含义是“不进行任何颜色混合”，即恢复原始颜色。
	# 这个动画会独立运行，即使 combo 数值再次变化，颜色也会在1秒后恢复。
	combo_color_tween.tween_property(combo_label, "self_modulate", Color.WHITE, 1.0)


# --- 播放闪红过渡动画的函数 ---
func play_danger_flash():
	if not is_instance_valid(danger_flash): return
	
	# 如果上一次闪烁还没结束，立刻停止
	if is_instance_valid(danger_tween):
		danger_tween.kill()
		
	danger_tween = create_tween()
	
	# 【核心修正 2】让手感更柔和：
	# a) 淡入时间稍微拉长一点 (0.25秒)，并且目标透明度不要太刺眼 (比如 0.75 而不是 1.0)
	danger_tween.tween_property(danger_flash, "modulate:a", 0.3, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# b) 消散时间拉长 (0.6秒)，像呼吸一样慢慢褪去
	danger_tween.tween_property(danger_flash, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
