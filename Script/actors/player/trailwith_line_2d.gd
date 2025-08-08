extends Line2D

@export var pointCount = 10
@export var isSpawn = false

func _physics_process(delta):
	#或者父节点Node不用重置
	global_position = Vector2.ZERO
	global_rotation = 0
	if isSpawn:
		if get_point_count() > pointCount:
			remove_point(0)
		drawPoint()
	else:
		if get_point_count() > 0:
			remove_point(0)
			
func drawPoint():
	add_point(get_parent().global_position)
	#用Node做父节点就没有globalposition,所以要用owner
