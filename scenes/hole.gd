
extends Area2D

var depth
const MAX_DEPTH=3
const MIN_DEPTH=0

func _ready():
	depth=MIN_DEPTH+1
	update_sprite()
	set_process(true)
	pass

func _process(delta):
	if depth==0:
		queue_free()
	pass

func update_sprite():
	var sprite=get_node("Sprite")
	sprite.set_frame(depth-1)

func dig():
	depth+=1
	check_depth()
	update_sprite()
	pass

func bury():
	depth-=1
	check_depth()
	update_sprite()
	pass

func check_depth():
	if depth>MAX_DEPTH:
		depth=MAX_DEPTH
	elif depth<MIN_DEPTH:
		depth=MIN_DEPTH
	pass
	
func is_completed():
	return depth == MAX_DEPTH