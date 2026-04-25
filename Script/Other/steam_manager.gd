# steam_manager.gd
extends Node

var is_steam_initialized: bool = false

func _ready() -> void:
	# 1. 初始化 Steam
	var init_response = Steam.steamInitEx()
	
	if init_response["status"] == 0: # 状态 0 表示成功
		is_steam_initialized = true
		print("--- Steam 初始化成功！欢迎玩家: ", Steam.getPersonaName(), " ---")
	else:
		print("--- Steam 初始化失败: ", init_response, " ---")

func _process(_delta: float) -> void:
	# 2. 维持 Steam 的心跳
	# 必须在 _process 中调用这个，Steam 才能正常接收和发送数据
	if is_steam_initialized:
		Steam.run_callbacks()

# --- 3. 封装一个通用的解锁成就函数 ---
func unlock_achievement(api_name: String) -> void:
	if not is_steam_initialized:
		return
		
	# 检查是否已经解锁过，防止重复发送请求浪费网络资源
	var achievement_data = Steam.getAchievement(api_name)
	var is_unlocked = achievement_data["achieved"]
	
	if not is_unlocked:
		# 告诉 Steam 解锁这个成就
		Steam.setAchievement(api_name)
		# 【极其重要】这行代码是把数据上传到 Steam 服务器，不写这行成就不跳！
		Steam.storeStats() 
		print("恭喜！解锁 Steam 成就: ", api_name)

func reset_all_achievements() -> void:
	if not is_steam_initialized:
		return
		
	# Steam.resetAllStats(true) 是一个底层 API
	# 括号里的 true 代表：不仅重置统计数据(Stats)，连成就(Achievements)也一起重置！
	var success = Steam.resetAllStats(true)
	
	if success:
		# 【必须有这一步】把“全部清零”的指令强制同步给 Steam 服务器
		Steam.storeStats()
		print("🛑 Steam 状态：所有成就已被系统强行重置！")
	else:
		print("❌ Steam 状态：重置成就失败，请确认 Steam 是否正常运行。")
