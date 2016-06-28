
extends Node2D

var read_time=0
const MAX_READ_TIME=0.3

func _ready():
	set_process(true)
	pass

func _process(delta):
	var add_credit=Input.is_action_pressed("add_credit")
	update_credit_value()
	if read_time < MAX_READ_TIME:
		read_time+=delta
		return
	else:
		read_time=0
	if add_credit:
		get_node("/root/global").credits+=1
	pass

func update_credit_value():
	get_node("Value").set_text(str(get_node("/root/global").credits).pad_zeros(2))
	pass
