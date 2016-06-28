
extends Node2D



func _ready():
	get_node("anim").play("animation")
	set_process(true)
	pass

func _process(delta):
	var anim=get_node("anim")
	if anim.is_playing():
		return
	else:
		get_node("/root/global").goto_scene("res://scenes/main.tscn")
	pass
