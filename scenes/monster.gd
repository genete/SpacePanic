
extends KinematicBody2D

const MOVE_LENGTH=4
const FALL_STEPS=8*4

var left_move=Vector2(-MOVE_LENGTH,0)
var right_move=Vector2(MOVE_LENGTH,0)
var up_move=Vector2(0,-MOVE_LENGTH)
var down_move=Vector2(0,MOVE_LENGTH)

var player
var navigation

var falling=false
var fall_step=0
var current_frame=0
var walk_speed=30
var fall_speed=walk_speed*4
var consumed_motion=0
var bury_speed=10
var depth_counter=1

const UPDATE_PATH_TIME=2
var update_path_counter=0

var uf=false
var df=false
var lf=true
var rf=true
var ray_cast_fall1=null
var ray_cast_fall2=null

var left=false
var right=false
var up=false
var down=false


var poses={ 
"walk1": 0,
"walk2": 1,
"climb": 4,
"dig1" : 2,
"dig2" : 3,
"fall" : 5
}

var hole_class=preload("res://scenes/hole.gd")


var begin=Vector2()
var end=Vector2()
var path=[]

func _ready():
	player=get_node("/root/Layout/Player")
	navigation=get_node("/root/Layout/Navigation2D")
	ray_cast_fall1=get_node("ray_cast_fall1")
	ray_cast_fall2=get_node("ray_cast_fall2")
	set_fixed_process(true)


func _fixed_process(delta):
	var speed
	var dir
	var fall1_colliding=ray_cast_fall1.is_colliding()
	var fall2_colliding=ray_cast_fall2.is_colliding()
	var hole_collided=null
	var over_a_hole=false

	if fall1_colliding and fall2_colliding:
		var hole1=ray_cast_fall1.get_collider()
		var hole2=ray_cast_fall1.get_collider()
		if hole1 !=null and hole2!=null and hole1 extends hole_class and hole2 extends hole_class:
			over_a_hole=true
			hole_collided=ray_cast_fall1.get_collider()
			set_pos(Vector2(get_pos().x, hole_collided.get_pos().y-12+(hole_collided.depth+depth_counter)*2))

	update_path_counter+=delta
	if update_path_counter >= UPDATE_PATH_TIME:
		update_path_counter=0
		_update_path()

	if over_a_hole:
		speed=bury_speed
	else:
		speed=walk_speed

	consumed_motion+=speed*delta
	# Return if not reached movement length
	if consumed_motion < MOVE_LENGTH:
		return
	else:
		consumed_motion=0

	# choose a direction
#	var mypos=get_pos()
#	var direction=player.get_pos()-mypos
#	var x=direction.x
#	var y=direction.y
#	dir = choose_direction_by_xy(x, y)

	
	if over_a_hole and not hole_collided.is_completed():
		dir=""
		var depth=hole_collided.depth
		var hole_pos=hole_collided.get_pos()
		depth_counter-=0.5
		if depth_counter == 0:
			hole_collided.bury()
			depth_counter=1
			if depth==1:
				set_pos(Vector2(get_pos().x, hole_pos.y-12))
	elif over_a_hole and hole_collided.is_completed():
		#change sprite quickly of hanging on
		# increase counter time hanging
		pass
	else:
		dir=_choose_direction_by_path()

	update_directions(dir)
	
	if left:
		move(left_move)
	elif right:
		move(right_move)
	elif up:
		move(up_move)
	elif down:
		move(down_move)
	
	if current_frame==poses["walk1"]:
		current_frame=poses["walk2"]
	else:
		current_frame=poses["walk1"]

	get_node("Sprite").set_frame(current_frame)

##################################################
func choose_direction(d1, d2, d3, d4):
	if d1=="left"  and lf==true: return "left"
	if d1=="right" and rf==true: return "right"
	if d1=="up"    and uf==true: return "up"
	if d1=="down"  and df==true: return "down"

	if d2=="left"  and lf==true: return "left"
	if d2=="right" and rf==true: return "right"
	if d2=="up"    and uf==true: return "up"
	if d2=="down"  and df==true: return "down"

	if d3=="left"  and lf==true: return "left"
	if d3=="right" and rf==true: return "right"
	if d3=="up"    and uf==true: return "up"
	if d3=="down"  and df==true: return "down"

	if d4=="left"  and lf==true: return "left"
	if d4=="right" and rf==true: return "right"
	if d4=="up"    and uf==true: return "up"
	if d4=="down"  and df==true: return "down"
	
	return d1

func choose_direction_by_xy(x, y):
	if x >= 0 and y >=0:
		if x >= y:
			return choose_direction("right", "down", "up", "left")
		else:
			return choose_direction("down", "right", "left", "up")
	elif x >=0 and y < 0:
		if x > -y:
			return choose_direction("right", "up", "down", "left")
		else:
			return choose_direction("up", "right", "left", "down")
	elif x < 0 and y >= 0:
		if -x < y:
			return choose_direction("down", "left", "right", "up")
		else:
			return choose_direction("left", "down", "up", "right")
	elif x < 0 and y < 0:
		if -x < -y:
			return choose_direction("up", "left", "right", "down")
		else:
			return choose_direction("left", "up", "down", "right")


func update_directions(d):
	if d=="left":
		left=true
		right=false
		up=false
		down=false
		return
	if d=="right":
		left=false
		right=true
		up=false
		down=false
		return
	if d=="up":
		left=false
		right=false
		up=true
		down=false
		return
	if d=="down":
		left=false
		right=false
		up=false
		down=true
		return
	left=false
	right=false
	up=false
	down=false
	

func _update_path():
	begin=get_pos()-navigation.get_pos()
	end=player.get_pos()-navigation.get_pos()
	var p=navigation.get_simple_path(begin, end, true)
	path=Array(p)
	path.invert()

func _choose_direction_by_path():
	var to_walk= MOVE_LENGTH
	if(path.size() > 1):
		var pfrom = path[path.size() - 1]
		var pto   = path[path.size() - 2]
		var direction=pto-pfrom
		var d = pfrom.distance_to(pto)
		if (d <= to_walk):
			path.remove(path.size() - 1)
		else:
			path[path.size() - 1] = pfrom.linear_interpolate(pto, to_walk/d)
		if (path.size() < 2):
			path = []
		var x=direction.x
		var y=direction.y
		var dir=choose_direction_by_xy(x, y)
		return dir
	return ""

