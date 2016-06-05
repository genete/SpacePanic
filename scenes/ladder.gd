
extends Node2D

var player_class=preload("res://scenes/player.gd")
var monster_class=preload("res://scenes/monster.gd")

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass


# UP DOWN FORBIDDEN
func _on_LR_body_enter( body ):
	if body extends player_class or body extends monster_class:
		body.uf=false
		body.df=false
		body.lf=true
		body.rf=true

# UP ALLOWED DOWN FORBIDDEN
func _on_U_body_enter( body ):
	if body extends player_class or body extends monster_class:
		body.uf=true
		body.df=false

# LEFT RIGTH FORBIDDEN UP DOWN ALLOWED
func _on_UD_body_enter( body ):
	if body extends player_class or body extends monster_class:
		body.uf=true
		body.df=true
		body.rf=false
		body.lf=false
		var pos=body.get_pos()
		body.set_pos(Vector2(get_parent().get_pos().x, pos.y))
		if body.has_method("enable_ray_casts"):
			body.enable_ray_casts(false)

# LEFT RIGHT ALLOWED
func _on_UD_body_exit( body ):
	if body extends player_class or body extends monster_class:
		body.rf=true
		body.lf=true
		if body.has_method("enable_ray_casts"):
			body.enable_ray_casts(true)


# DOWN ALLOWED UP FORBIDDEN
func _on_D_body_enter( body ):
	if body extends player_class or body extends monster_class:
		body.uf=false
		body.df=true



func _on_UDLR_body_enter( body ):
	if body extends player_class or body extends monster_class:
		body.uf=true
		body.df=true
