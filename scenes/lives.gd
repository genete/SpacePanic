
extends Node2D

var live_icon_tex=preload("res://images/live_icon.png")

func _ready():
	var total_lives=get_node("/root/global").player1_lives
	for i in range(0, total_lives):
		var live_node=Sprite.new()
		live_node.set_centered(false)
		live_node.set_texture(live_icon_tex)
		live_node.set_pos(Vector2(16+12*i,240))
		add_child(live_node)
		live_node.set_name("live_icon"+str(i))
		pass

	pass


