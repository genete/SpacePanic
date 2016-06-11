
extends KinematicBody2D

const MOVE_LENGTH=4
const FALL_STEPS=8*4

var left_move=Vector2(-MOVE_LENGTH,0)
var right_move=Vector2(MOVE_LENGTH,0)
var up_move=Vector2(0,-MOVE_LENGTH)
var down_move=Vector2(0,MOVE_LENGTH)

var siding_right=true
var falling=false
var fall_step=0
var current_frame=0
var walk_speed=60
var fall_speed=walk_speed*4
var dig_speed=15
var consumed_motion=0
var was_facing_a_hole=false

# Up down left right flags
var uf=false
var df=false
var lf=true
var rf=true
var promote_left=false
var promote_right=false
var ray_cast_near=null
var ray_cast_far=null
var ray_cast_hole=null
var ray_cast_fall1=null
var ray_cast_fall2=null
var ray_cast_monster=null

var poses={ 
"walk1": 0,
"walk2": 1,
"climb": 4,
"dig1" : 2,
"dig2" : 3,
"fall" : 5
}

var hole_class=preload("res://scenes/hole.gd")
var hole_scene=preload("res://scenes/hole.tscn")

func _ready():
##### TO BE REMOVED 
	OS.set_window_size(Vector2(192, 256)*4)
###################
	ray_cast_near=get_node("ray_cast_near")
	ray_cast_far=get_node("ray_cast_far")
	ray_cast_hole=get_node("ray_cast_hole")
	ray_cast_fall1=get_node("ray_cast_fall1")
	ray_cast_fall2=get_node("ray_cast_fall2")
	ray_cast_monster=get_node("ray_cast_monster")
	set_fixed_process(true)
	pass


func _fixed_process(delta):
	# Read inputs
	var left=Input.is_action_pressed("ui_left")
	var right=Input.is_action_pressed("ui_right")
	var up=Input.is_action_pressed("ui_up")
	var down=Input.is_action_pressed("ui_down")
	var dig=Input.is_action_pressed("dig")
	var bury=Input.is_action_pressed("bury")

	# Calculate speed
	var speed
	if bury or dig:
		speed=dig_speed
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
	#Helping variables
	var digging=bury or dig
	var moving=left or right or up or down
	var far_colliding=ray_cast_far.is_colliding()
	var near_colliding=ray_cast_near.is_colliding()
	var hole_colliding=ray_cast_hole.is_colliding()
	var both_colliding=near_colliding and far_colliding
	var one_colliding=near_colliding or far_colliding
	var fall1_colliding=ray_cast_fall1.is_colliding()
	var fall2_colliding=ray_cast_fall2.is_colliding()
	var monster_colliding=ray_cast_monster.is_colliding()
	var monster_collided=ray_cast_monster.get_collider()
	var on_floor=lf or rf
	var collider1=null
	var collider2=null
	var hole_collided=null
	var facing_hole=false
	if both_colliding:
		collider1=ray_cast_far.get_collider()
		collider2=ray_cast_near.get_collider()
		if collider1!=null and collider2!=null and collider1 extends hole_class and collider2 extends hole_class:
			if collider1.get_instance_ID() == collider2.get_instance_ID():
				facing_hole=true
				hole_collided=collider1


	
	var can_dig = ((not one_colliding and not hole_colliding) or facing_hole) and on_floor
	if monster_collided!=null and (monster_collided.burying0 or monster_collided.burying1):
		can_dig=false
	# Pre-process inputs with flags
	#If player is on ladder and want to go right or left
	if (not lf and not rf and (up or down) and (right or left)):
		promote_left=true
		promote_right=true
	#If player is on floor and want to go up or down
	if (not uf and not df and (right or left) and (up or down)):
		promote_left=false
		promote_right=false
	# Can't pass an incomplete hole
	if facing_hole:
		was_facing_a_hole=true
		if hole_collided.is_completed() and not monster_colliding:
			if siding_right:
				rf=true
			else:
				lf=true
		else:
			if siding_right:
				rf=false
			else:
				lf=false
	else:
		if was_facing_a_hole:
			was_facing_a_hole=false
		# Restore lf an rf if not facing a hole
			if lf:
				rf=true
			elif rf:
				lf=true

	if fall1_colliding and fall2_colliding and not falling:
		print("falling = true")
		set_pos(Vector2(ray_cast_fall1.get_collider().get_pos().x, get_pos().y))
		update_scale()
		falling=true
		get_node("sprite").set_frame(poses["fall"])


	if falling:
		fall_step+=1
#		print(fall_step)
		move(down_move/4)
		if fall_step>=FALL_STEPS:
			fall_step=0
			#Read ray casting again
			fall1_colliding=ray_cast_fall1.is_colliding()
			fall2_colliding=ray_cast_fall2.is_colliding()
			if not (fall1_colliding and fall2_colliding):
				print("falling false")
				print("siding right = ", siding_right)
				falling=false
				speed=walk_speed
				get_node("sprite").set_frame(poses["walk1"])
		return


	# Process inputs
	#Movements
	if left and (not digging) and lf:
		if siding_right:
			siding_right=false
			update_scale()
		if current_frame==poses["walk1"]:
			current_frame=poses["walk2"]
		else:
			current_frame=poses["walk1"]
		get_node("sprite").set_frame(current_frame)
		move(left_move)
		if promote_left: return

	if right and (not digging) and rf:
		if not siding_right:
			siding_right=true
			update_scale()
		if current_frame==poses["walk1"]:
			current_frame=poses["walk2"]
		else:
			current_frame=poses["walk1"]
		get_node("sprite").set_frame(current_frame)

		move(right_move)
		if promote_right : return

	if up and (not digging) and uf:
		if not current_frame==poses["climb"]:
			current_frame=poses["climb"]
		if not siding_right:
			siding_right=true
			update_scale()
		else:
			siding_right=false
			update_scale()
		get_node("sprite").set_frame(current_frame)
		move(up_move)

	if down and (not digging) and df:
		if not current_frame==poses["climb"]:
			current_frame=poses["climb"]
		if not siding_right:
			siding_right=true
			update_scale()
		else:
			siding_right=false
			update_scale()
		get_node("sprite").set_frame(current_frame)
		move(down_move)
	
	#print("pos:x = ", get_pos().x, "; pos:y = ", get_pos().y) 
	#Digging/burying
	#If player can dig
	if can_dig:
		# Now let's check if it is creating a hole or not.
		if dig:
			if facing_hole:
				if current_frame==poses["dig1"]: 
					# End dig pose and increase hole depth
					current_frame=poses["dig2"]
					get_node("sprite").set_frame(current_frame)
					hole_collided.dig()
				else:
					current_frame=poses["dig1"]
					get_node("sprite").set_frame(current_frame)
					return
			else:
				# Drop a hole
				if current_frame==poses["dig1"]: 
					current_frame=poses["dig2"]
					get_node("sprite").set_frame(current_frame)
					var hole_instance=hole_scene.instance()
					var holes=get_node("/root/Layout/Holes")
					holes.add_child(hole_instance)
					var player_pos=get_pos()
					var rcf_pos=ray_cast_far.get_pos()
					var rcn_pos=ray_cast_near.get_pos()
					var hole_tex_height=hole_instance.get_node("Sprite").get_texture().get_height()
					var player_tex_height=get_node("sprite").get_texture().get_height()
					var hole_pos
					if siding_right:
						hole_pos=Vector2(player_pos.x+(rcf_pos.x+rcn_pos.x)/2, player_pos.y+(player_tex_height+hole_tex_height)/2)
					else:
						hole_pos=Vector2(player_pos.x-(rcf_pos.x+rcn_pos.x)/2, player_pos.y+(player_tex_height+hole_tex_height)/2)
					print (hole_pos)
					hole_instance.set_pos(hole_pos)
					return
				else:
					# Start dig pose
					current_frame=poses["dig1"]
					get_node("sprite").set_frame(current_frame)
					return
		if bury:
			if facing_hole:
				if current_frame==poses["dig2"]:
					current_frame=poses["dig1"]
					get_node("sprite").set_frame(current_frame)
					hole_collided.bury()
				else:
					current_frame=poses["dig2"]
					get_node("sprite").set_frame(current_frame)
					return


func update_scale():
	if siding_right:
		scale(Vector2(1,1))
	if not siding_right:
		scale(Vector2(-1,1))

func enable_ray_casts(enabled):
	get_node("ray_cast_near").set_enabled(enabled)
	get_node("ray_cast_far").set_enabled(enabled)
	get_node("ray_cast_hole").set_enabled(enabled)
	get_node("ray_cast_fall1").set_enabled(enabled)
	get_node("ray_cast_fall2").set_enabled(enabled)
