
extends Node2D

const Y=37
const OXYGENP=120
const NOXYGENP=56
const REDX0=192-8
const REDX1=REDX0-NOXYGENP
const YELLOWX0=REDX1
const YELLOWX1=YELLOWX0-OXYGENP
const COLOR_RED=Color(1, 0, 0, 1)
const COLOR_YELLOW=Color(1, 1, 165/255.0, 1)
const OXYGEN_STEP=20.0

var bar_step

var red_origin=Vector2(REDX0, Y)
var red_end

var yellow_origin=Vector2(YELLOWX0, Y)
var yellow_end

const WIDTH=24

var oxygen
var started

const BREATH_TIME=2/25.0
var passed_time=0

signal oxygen_out
signal player_died

func _ready():
	reset_oxygen(2000)
	set_process(true)
	start()
	add_user_signal("oxygen_out")
	add_user_signal("player_died")
	connect("oxygen_out", get_node("/root/Layout/Player"), "callback_oxygen_finished")
	connect("player_died", get_node("/root/Layout/Player"), "callback_player_died_asphyxiated")
	pass


func _process(delta):
	if started:
		passed_time+=delta
		if passed_time<BREATH_TIME:
			return
		else:
			passed_time=0
			yellow_end.x=yellow_end.x+bar_step
			oxygen=oxygen-OXYGEN_STEP
			if oxygen<=0:
				yellow_end.x=YELLOWX0
				if oxygen<0:
					emit_signal("oxygen_out")
					red_end.x+=bar_step
					if red_end.x >=REDX0:
						emit_signal("player_died")
						red_end.x=REDX0
	update_value()
	update()
	pass

func _draw():
	draw_line(red_origin, red_end, COLOR_RED, WIDTH)
	draw_line(yellow_origin, yellow_end, COLOR_YELLOW, WIDTH)
	pass 
	
	
func reset_oxygen(o):
	oxygen=o
	bar_step= OXYGENP/(oxygen/OXYGEN_STEP)
	red_end=Vector2(REDX1, Y)
	yellow_end=Vector2(YELLOWX1, Y)
	stop()

func start():
	started=true

func stop():
	started=false

func update_value():
	var o
	if oxygen<0:
		o=0
	else:
		o=oxygen
	get_node("Value").set_text(str(o))
	