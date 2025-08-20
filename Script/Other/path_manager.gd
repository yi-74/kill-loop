# path_manager.gd
extends Node

# --- 用来记录每条路径及其占用状态 ---
# 结构: { path_node: Path2D, is_occupied: bool }
var patrol_paths: Array = []

func _ready() -> void:
	# 游戏开始时，扫描自己所有的子节点，把它们都登记到路径池里
	for child in get_children():
		if child is Path2D:
			patrol_paths.append({
				"path_node": child,
				"is_occupied": false
			})

# --- 提供给 EnemySpawner 调用的函数 ---
func request_free_path() -> Path2D:
	# 遍历所有路径，寻找一条未被占用的
	for path_info in patrol_paths:
		if not path_info.is_occupied:
			path_info.is_occupied = true # 标记为“已占用”
			return path_info.path_node # 返回这条路径节点
			
	# 如果没有找到任何空闲路径，返回 null
	return null

# --- 用来接收敌人死亡信号的函数 ---
func release_path(path_node_to_release: Path2D):
	# 遍历所有路径，找到被释放的那一条
	for path_info in patrol_paths:
		if path_info.path_node == path_node_to_release:
			path_info.is_occupied = false # 重新标记为“未占用”
			return
