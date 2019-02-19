extends KinematicBody2D

enum ACTIONS {
	IDLE, 
	RUNNING, 
	SLIDING, 
	STANDING, 
	CROUCHING, 
	JUMPING, 
	DOUBLE_JUMPING,
	FALLING,
	ATTACKING, 
	AIR_ATTACK1,
	CASTING,
	SWORD_SEATH
}

onready var anim_player = get_node("AnimatedSprite")

const SPEED = 20
const GRAVITY = 10
const FLOOR = Vector2(0, -1)

var velocity = Vector2()
var current_action = null
var direction = 1  # track the enemy's direction (1 = right)

var is_dead = false

func _ready():
	pass # Replace with function body.

func dead():
	is_dead = true
	velocity = Vector2(0, 0)  # stop moving
#	$CollisionShape2D.disabled = true
	$CollisionShape2D.queue_free()
	$edge_detector.enabled = false
	anim_player.play("die")
	$after_death_timer.start()

func _physics_process(delta):
	
	if not is_dead:
		velocity.x = SPEED * direction
		
		anim_player.play("walk")
		
		velocity.y += GRAVITY
		
		velocity = move_and_slide(velocity, FLOOR)
		
		if direction == 1:
			anim_player.flip_h = false
		else:
			anim_player.flip_h = true
		
		if is_on_wall():
			_change_direction()
		
		if get_node("edge_detector").is_colliding() == false:
			# we hit a ledge
			_change_direction()
		
func _change_direction():
	direction *= -1
	$edge_detector.position.x *= -1

func _on_after_death_timer_timeout():
	queue_free()
