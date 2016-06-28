
extends Node2D



func _ready():
	OS.set_window_size(Vector2(192, 256)*4)
	get_node("anim").play("main")
	set_process(true)
	pass

func _process(delta):
	var anim=get_node("anim")
	if anim.is_playing():
		return
	else:
		get_node("/root/global").goto_scene("res://scenes/scoring.tscn")
	pass
