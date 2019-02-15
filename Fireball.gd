extends Area2D


const SPEED = 100
var velocity = Vector2()
var direction = 1  # default facing right

func _ready():
	pass
	
func set_fireball_direction(facing_right):
	if facing_right:
		direction = 1
	else:
		direction = -1
	
func _process(delta):
	velocity.x = SPEED * delta * direction
	translate(velocity)  # moves the fireball
	
func _on_screen_exited():
	queue_free()

func _on_Fireball_body_entered(body):
	queue_free()