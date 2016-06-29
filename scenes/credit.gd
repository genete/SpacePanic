
extends Node2D

func _ready():
	set_process_input(true)
	update_credit_value()

func _input(event):
	if event.is_action_pressed("add_credit") and not event.is_echo():
		get_node("/root/global").credits+=1
		update_credit_value()
		if get_parent().get_name()!="Push_Start":
			get_node("/root/global").goto_scene("res://scenes/push_start.tscn")

func update_credit_value():
	get_node("Value").set_text(str(get_node("/root/global").credits).pad_zeros(2))