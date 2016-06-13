
extends KinematicBody2D

const MOVE_LENGTH=4
const FALL_STEPS=8*4
const MAX_HANGING_COUNTER=200

var left_move=Vector2(-MOVE_LENGTH,0)
var right_move=Vector2(MOVE_LENGTH,0)
var up_move=Vector2(0,-MOVE_LENGTH)
var down_move=Vector2(0,MOVE_LENGTH)

var player
var navigation
var ray_cast_fall1
var ray_cast_fall2
var ray_cast_monster_left
var ray_cast_monster_right
var ray_cast_monster_kill

#States, speeds and counters
var state={
"walking": true,
"burying0": false,
"burying1": false,
"hanging": false,
"falling": false,
"dying": false
}
var walking=state["walking"]
var burying0=state["burying0"]
var burying1=state["burying1"]
var hanging=state["hanging"]
var falling=state["falling"]
var dying=state["dying"]

var walk_speed=30
var bury0_speed=10
var bury1_speed=10
var fall_speed=walk_speed*4
var hang_speed=100

var depth_counter=1
var fall_step=0
var current_frame=0
var consumed_motion=0
var holes_crossed=0
var minimum_holes_to_die=1
var burying0_sprite_counter=4
var hanging_counter=MAX_HANGING_COUNTER
var hanging_sprite_counter=2

#Navigation related
var hunting_radius=40
const UPDATE_PATH_STEPS=40
var update_path_counter=0
var begin=Vector2()
var end=Vector2()
var path=[]

#Walking flags
var uf=false
var df=false
var lf=true
var rf=true

#walking directions
var left=false
var right=false
var up=false
var down=false


var poses={ 
"walking1": 0,
"walking2": 1,
"hanging1" : 5,
"hanging2" : 6,
"burying01" : 2,
"burying02" : 3,
"burying03" : 4,
"burying04" : 5,
"burying05" : 6,
"burying11" : 0,
"burying12" : 1,
"falling" : 0
}

var hole_class=preload("res://scenes/hole.gd")
var monster_class=get_script()


func _ready():
	randomize()
	player=get_node("/root/Layout/Player")
	navigation=get_node("/root/Layout/Navigation2D")
	ray_cast_fall1=get_node("ray_cast_fall1")
	ray_cast_fall2=get_node("ray_cast_fall2")
	ray_cast_monster_left=get_node("ray_cast_monster_left")
	ray_cast_monster_right=get_node("ray_cast_monster_right")
	ray_cast_monster_kill=get_node("ray_cast_monster_kill")
	set_fixed_process(true)


func _fixed_process(delta):
	var speed
	var dir
	var fall1_colliding=ray_cast_fall1.is_colliding()
	var fall2_colliding=ray_cast_fall2.is_colliding()
	var monster_left_colliding=ray_cast_monster_left.is_colliding()
	var monster_right_colliding=ray_cast_monster_right.is_colliding()
	var monster_kill_colliding=ray_cast_monster_kill.is_colliding()
	var hole_collided=null
	var over_a_hole=false


	#Hole rays collided? 
	# Result:
	# over_a_hole=true/false
	# hole_collided=hole object 
	if fall1_colliding and fall2_colliding:
		var hole1=ray_cast_fall1.get_collider()
		var hole2=ray_cast_fall1.get_collider()
		if hole1 !=null and hole2!=null and hole1 extends hole_class and hole2 extends hole_class:
			over_a_hole=true
			hole_collided=ray_cast_fall1.get_collider()


# Monster is OVER A HOLE
	if over_a_hole:
		if walking:
			if hole_collided.is_completed():
				change_state_to("hanging")
				set_pos(Vector2(get_pos().x, hole_collided.get_pos().y+4))
			else:
				change_state_to("burying1")
				set_pos(Vector2(get_pos().x, hole_collided.get_pos().y-12+(hole_collided.depth+depth_counter)*2))
		else:
			if falling and fall_step==0:
				holes_crossed+=1

# Monster is NOT OVER A HOLE
	else:
		if burying1:
			change_state_to("walking")
		if hanging:
			change_state_to("falling")
			current_frame=poses["falling"]
			fall_step=16
			print("*fall step ", fall_step)
			holes_crossed+=1
		if falling: 
			if monster_kill_colliding:
				print("monster kill colliding")
				var monster=ray_cast_monster_kill.get_collider()
				if monster!=null and monster extends monster_class:
					monster.change_state_to("dying")
					print("to dying")
					change_state_to("dying")
			if falling and fall_step==0:
				if holes_crossed < minimum_holes_to_die:
					change_state_to("walking")
				else:
					print("to dying")
					change_state_to("dying")

# Update speeds state based
	if walking:
		speed=walk_speed
	elif burying0:
		speed=bury0_speed
	elif burying1:
		speed=bury1_speed
	elif hanging:
		speed=hang_speed
	elif falling:
		speed=fall_speed
	else:
		speed=walk_speed


	consumed_motion+=speed*delta
	# Return if not reached movement length
	if not falling:
		if consumed_motion < MOVE_LENGTH:
			return
		else:
			consumed_motion=0
	if falling:
		if consumed_motion < MOVE_LENGTH/4:
			return
		else:
			consumed_motion=0

	if walking:
#		update_path_counter+=1
#		if update_path_counter >= UPDATE_PATH_STEPS:
#			update_path_counter=0
#			_update_path()
#			dir=_choose_direction_by_path()
#		else:
		if monster_left_colliding:
			lf=false
		if monster_right_colliding:
			rf=false
		var distance=Vector2()
		distance=_update_path()
		if distance.length()>hunting_radius:
			dir=_walk_free()
		else:
			dir=_choose_direction_by_path()
		update_directions(dir)
		update()
		if left and not monster_left_colliding:
			move(left_move)
		elif right and not monster_right_colliding:
			move(right_move)
		elif up:
			move(up_move)
		elif down:
			move(down_move)
		if current_frame==poses["walking1"]:
			current_frame=poses["walking2"]
		else:
			current_frame=poses["walking1"]

	
	if burying1:
		var depth=hole_collided.depth
		var hole_pos=hole_collided.get_pos()
		depth_counter-=0.5
		if depth_counter == 0:
			hole_collided.bury()
			depth_counter=1
		if depth==1:
			set_pos(Vector2(get_pos().x, hole_pos.y-12))
			#change_state_to("walking")
			# evolve
		else:
			set_pos(Vector2(get_pos().x, hole_collided.get_pos().y-12+(hole_collided.depth+depth_counter)*2))
		if current_frame==poses["burying12"]:
			current_frame=poses["burying11"]
		else:
			current_frame=poses["burying12"]

	if burying0:
		depth_counter-=0.2
		if depth_counter<=1:
			change_state_to("burying1")
			set_pos(Vector2(get_pos().x, hole_collided.get_pos().y-12+(hole_collided.depth+depth_counter)*2))
			current_frame=poses["burying11"]
			depth_counter=1
			burying0_sprite_counter=4
		else:
			print("burying0 counter ", burying0_sprite_counter)
			print("depth_counter ", depth_counter)
			current_frame=poses["burying0"+str(burying0_sprite_counter)]
			burying0_sprite_counter-=1

	if hanging:
		hanging_counter-=1
		if hanging_counter<=0:
			change_state_to("burying0")
			hanging_counter=MAX_HANGING_COUNTER
			depth_counter=2 #change here to match burying0 frames
		current_frame=poses["hanging"+str(hanging_sprite_counter)]
		hanging_sprite_counter-=1
		if hanging_sprite_counter<=0:
			hanging_sprite_counter=2

	if falling:
		fall_step+=1
		move(down_move/4)
		print("fall step ", fall_step)
		if fall_step>=FALL_STEPS:
			fall_step=0
	
	if dying:
		# signal points
		die()

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
	return end-begin

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

# left, right, up, down
# lf, rf, uf, df
func _walk_free():
	if not rf and not lf and not uf and not df:
		return ""
	#forced
	if lf and not rf and not uf and not df:
		return "left"
	if not lf and rf and not uf and not df:
		return "right"
	if not lf and not rf and uf and not df:
		return "up"
	if not lf and not rf and not uf and df:
		return "down"
	#bifurcation by two
	if lf and rf and not uf and not df:
		if left:
			return "left"
		if right:
			return "right"
		if randf()>0.5: return "left"
		else: return "right"
	if uf and df and not rf and not lf:
		if up:
			return "up"
		if down:
			return "down"
		if randf()>0.5: return "up"
		else: return "down"
	if uf and rf and not df and not lf:
		if up:
			return "up"
		if right:
			return "right"
		if randf()>0.5: return "up"
		else: return "right"
	if df and rf and not uf and not lf:
		if down:
			return "down"
		if right:
			return "right"
		if randf()>0.5: return "down"
		else: return "right"
	if uf and lf and not df and not rf:
		if up:
			return "up"
		if left:
			return "left"
		if randf()>0.5: return "up"
		else: return "left"
	if df and lf and not uf and not rf:
		if up:
			return "down"
		if left:
			return "left"
		if randf()>0.5: return "down"
		else: return "left"
	# bifurcation by three
	if lf and rf and uf and not df:
		if left:
			if randf()>0.5: return "left"
			else: return "up"
		if right:
			if randf()>0.5: return "right"
			else: return "up"
		if up or down:
			if randf()>0.5: return "left"
			else: return "right"
	if lf and rf and df and not uf:
		if left:
			if randf()>0.5: return "left"
			else: return "down"
		if right:
			if randf()>0.5: return "right"
			else: return "down"
		if down or up:
			if randf()>0.5: return "left"
			else: return "right"
	if lf and uf and df and not rf:
		if left or right:
			if randf()>0.5: return "up"
			else: return "down"
		if up:
			if randf()>0.5: return "up"
			else: return "left"
		if down:
			if randf()>0.5: return "down"
			else: return "left"
	if rf and uf and df and not lf:
		if right or left:
			if randf()>0.5: return "up"
			else: return "down"
		if up:
			if randf()>0.5: return "up"
			else: return "right"
		if down:
			if randf()>0.5: return "down"
			else: return "right"
	# bifurcatrion by four
#	if left:
#		rf=false
#		return _walk_free()
#	if right:
#		lf=false
#		return _walk_free()
#	if up:
#		df=false
#		return _walk_free()
#	if down:
#		uf=false
#		return _walk_free()
	if randf()>=0.5:
		if randf()>0.5:
			return "left"
		else:
			return "right"
	elif randf()>=0.5: 
		if randf()>0.5:
			return "up"
		else: 
			return "down"
	pass


func change_state_to(new_state):
	for s in ["walking", "burying0", "burying1", "hanging", "falling", "dying"]:
		if s==new_state:
			state[s]=true
		else:
			state[s]=false
	walking=state["walking"]
	burying0=state["burying0"]
	burying1=state["burying1"]
	hanging=state["hanging"]
	falling=state["falling"]
	dying=state["dying"]
	print("**** new state = ", new_state)

func die():
	queue_free()
	pass

func _draw():
	draw_circle(Vector2(0,0), hunting_radius, Color(1,1,1,0.3)) 
