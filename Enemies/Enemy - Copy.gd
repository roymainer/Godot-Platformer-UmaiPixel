extends KinematicBody2D

enum ACTIONS {
	IDLE, 
	WALK,
	ATTACK,
	HURT,
	DIE,
}

onready var anim_player = get_node("AnimatedSprite")
onready var player_detector_front = get_node("player_detector_front")
onready var player_detector_back = get_node("player_detector_back")
onready var player_in_range = get_node("player_in_range_detector")
onready var myname = self.name

const SPEED = 20
const MAX_SPEED = 40
const GRAVITY = 10
const FLOOR = Vector2(0, -1)
const MAX_HEALTH = 50
const DAMAGE = 10

var velocity = Vector2()
var current_action = null
var direction = 1  # track the enemy's direction (1 = right)
export (int) var max_health = MAX_HEALTH
var health
var is_dead = false
var is_hurt = false

signal health_changed

func _ready():
	current_action = ACTIONS.WALK
	health = max_health


#warning-ignore:unused_argument
func _physics_process(delta):
	
	if not is_dead and not is_hurt:
		
		velocity.y += GRAVITY
		
		if _detect_player():
			pass
		
		elif is_on_wall():
#			print(name + ": reached wall")
			_move_from_edge()
		
		elif get_node("edge_detector").is_colliding() == false:
			# we hit a ledge
#			print(name + ": reached edge")
			_move_from_edge()
			
		velocity = move_and_slide(velocity, FLOOR)
		
	animate()	
#	print(name + ": action: " + str(current_action))
	
	
func animate():
	
	match current_action:
		
		ACTIONS.IDLE:
			velocity.x = 0
			anim_player.play("idle")
			
		ACTIONS.WALK:
			if player_detector_front.is_colliding():
				if player_detector_front.get_collider().name == "Player":
					velocity.x = MAX_SPEED * direction
			else:
				velocity.x = SPEED * direction
			anim_player.play("walk")
		
		ACTIONS.ATTACK:
			anim_player.play("attack")
		
		ACTIONS.HURT:
			anim_player.play("hurt")
		
		ACTIONS.DIE:
			anim_player.play("die")
	
func _detect_player():
	if player_detector_front.is_colliding():
		if player_detector_front.get_collider().name == "Player":
			velocity.x = MAX_SPEED * direction
	elif player_detector_back.is_colliding():
		if player_detector_back.get_collider().name == "Player":
			_change_direction()
			velocity.x = MAX_SPEED * direction
	else:
		velocity.x = SPEED * direction
		
	if player_in_range.is_colliding():
		var collider = player_in_range.get_collider()
		if collider.name == "Player":
			velocity.x = 0
			current_action = ACTIONS.ATTACK
		return true
	else:
		return false
#			collider.hit(DAMAGE)
#	else:
#		# player is not in enemy range
#		if velocity.x == 0:
#			velocity.x = SPEED * direction
#		current_action = ACTIONS.WALK
			
	
func _move_from_edge():
	if $wait_near_edge_timer.time_left == 0:
		$wait_near_edge_timer.start()
	current_action = ACTIONS.IDLE
	velocity.x = 0

func _change_direction():
	direction *= -1
	$edge_detector.position.x *= -1
	player_detector_front.cast_to.x *= -1
	player_detector_back.cast_to.x *= -1
	player_in_range.cast_to.x *= -1
	
	if direction == 1:
		anim_player.flip_h = false
	else:
		anim_player.flip_h = true
		
	velocity.x = SPEED * direction

func hit(damage):
	health -= damage
	health = clamp(health, 0, MAX_HEALTH)
	emit_signal("health_changed", health * 100/MAX_HEALTH)
	
	current_action = ACTIONS.HURT
	is_hurt = true
	if anim_player.get_animation() == "hurt":
		anim_player.set("frame", 0)
	if health == 0:
		dead()
	
func dead():
	current_action = ACTIONS.DIE
	is_dead = true
	velocity = Vector2(0, 0)  # stop moving
#	$CollisionShape2D.disabled = true
	$CollisionShape2D.queue_free()
	$edge_detector.queue_free()
	$UnitDisplay.hide()
	$after_death_timer.start()

func _on_after_death_timer_timeout():
	queue_free()

func _on_wait_near_edge_timer_timeout():
	if not is_dead:
		_change_direction()
		current_action = ACTIONS.WALK

func _on_animation_finished():
	var animation = anim_player.get_animation()
	if animation == "attack" and current_action == ACTIONS.ATTACK:
		anim_player.set("frame", 0)  # restart the animation		
	if animation == "hurt":
		is_hurt = false
		


func _on_frame_changed():
	if anim_player.get_animation() == "attack" and anim_player.frame == 7:
		if player_in_range.is_colliding():
			var collider = player_in_range.get_collider()
			if collider.name == "Player":
				velocity.x = 0
				current_action = ACTIONS.ATTACK
				collider.hit(DAMAGE)  # only hit if the player is in range by the time the animation finishes
	
