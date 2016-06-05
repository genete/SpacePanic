
extends Area2D

var player_node
var monsters_node

func _ready():
	player_node=get_node("/root/Layout/Player")
	monsters_node=get_node("/root/Layout/Monsters")
	set_process(true)
	pass

func _process(delta):
	if overlaps_body(player_node):
		player_node.rf=false
	for i in range(0, monsters_node.get_child_count()):
		var monster=monsters_node.get_child(i)
		if overlaps_body(monster):
			monster.rf=false
	pass
	
