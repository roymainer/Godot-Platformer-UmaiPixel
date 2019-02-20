extends Area2D


const SPEED = 150
var velocity = Vector2()
var direction = 1  # default facing right
var hit = false

func _ready():
	$explosion.emitting = false
	pass
	
func set_fireball_direction(facing_right):
	if facing_right:
		direction = 1
	else:
		direction = -1
	
func _process(delta):
	if not hit:
		velocity.x = SPEED * delta * direction
		translate(velocity)  # moves the fireball
	
func _on_screen_exited():
	$screen_exited_timer.start()

func _on_Fireball_body_entered(body):
	if "Enemy" in body.name:
		body.dead()
	_explode()

func _explode():
	hit = true
	velocity = Vector2(0,0)
	$explosion_timer.start()
	$explosion.emitting = true
	$Particles2D.queue_free()  # hide the fireball itself
	$CollisionShape2D.queue_free()  # eliminate the collision shape
		
func _on_screen_exited_timer_timeout():
	queue_free()

func _on_explosion_timer_timeout():
	queue_free()
