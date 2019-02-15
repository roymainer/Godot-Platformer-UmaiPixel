extends KinematicBody2D

enum ACTIONS {
	IDLE, 
	RUNNING, 
	SLIDING, 
	STANDING, 
	CROUCHING, 
	JUMPING, 
	FALLING,
	ATTACKING, 
	CASTING,
	SWORD_SEATH
}

onready var anim_player = get_node("AnimatedSprite")
onready var stand_col_shape = get_node("stand_collision_shape")

const SPEED = 120
const GRAVITY = 10
const JUMP_POWER = -250
const FLOOR = Vector2(0, -1)
const FIREBALL = preload("res://Fireball.tscn")

var velocity = Vector2()

var current_action = null
var is_sword_out = false


func get_input():
	
	""" RUNNING """
	if current_action != ACTIONS.ATTACKING and current_action != ACTIONS.CASTING:
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d_pressed"):
			velocity.x = SPEED  # update horizontal velocity to move right
			anim_player.flip_h = false
			if sign($Position2D.position.x) == -1: 
				$Position2D.position.x *= -1  # invert the x position of the shooting "cursor"
			if is_on_floor():
				current_action = ACTIONS.RUNNING  # set action to running
				 
		elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("a_pressed"):
			velocity.x = -SPEED
			anim_player.flip_h = true
			if sign($Position2D.position.x) == 1:
				$Position2D.position.x *= -1  # invert the x position of the shooting "cursor"
			if is_on_floor():
				current_action = ACTIONS.RUNNING
		else:
			velocity.x = 0
			if is_on_floor() == true and current_action != ACTIONS.ATTACKING and current_action != ACTIONS.SWORD_SEATH:
				current_action = ACTIONS.IDLE
				var sword_timer = get_node("sword_seath_timer")
				if is_sword_out and sword_timer.time_left == 0:
					print("starting sword seath timer")
					sword_timer.start()
				
		""" CROUCH and SLIDE """
		if (Input.is_action_pressed("ui_down") or Input.is_action_pressed("s_pressed")) and is_on_floor():
			if velocity.x == 0:
				current_action = ACTIONS.CROUCHING
			elif get_node("slide_cooldown_timer").time_left == 0:
				current_action = ACTIONS.SLIDING
				var slide_timer = get_node("slide_timer")
				if slide_timer.time_left == 0:
					print("starting slide timer")
					slide_timer.start()
			stand_col_shape.disabled = true
		else:
			stand_col_shape.disabled = false
					
		if (Input.is_action_just_released("ui_down") or Input.is_action_just_released("s_pressed")):
			get_node("slide_timer").stop()
			get_node("slide_cooldown_timer").stop()
			
			
		""" JUMPING """
		if Input.is_action_just_pressed("ui_up") and is_on_floor():#  and current_action != ACTIONS.ATTACKING:
			velocity.y = JUMP_POWER
		if velocity.y < 0:
			current_action = ACTIONS.JUMPING
		elif velocity.y > 0 and not is_on_floor():
			current_action = ACTIONS.FALLING
		
	""" Normal Attacking """
	if Input.is_action_just_pressed("ui_focus_next") and current_action != ACTIONS.CASTING: # and not is_attacking and is_on_floor():
		if abs(velocity.x) > 0:
			velocity.x -= sign($Position2D.position.x)*SPEED/2  # slow down when attacking
		current_action = ACTIONS.ATTACKING
		is_sword_out = true
		get_node("sword_seath_timer").stop()
		
	""" Casting """
	if Input.is_action_just_pressed("ui_select") and current_action != ACTIONS.ATTACKING: # and not is_attacking:
		if abs(velocity.x) > 0:
			velocity.x -= sign($Position2D.position.x)*SPEED/2  # slow down when casting
		current_action = ACTIONS.CASTING  
		var fireball = FIREBALL.instance()
		get_parent().add_child(fireball)  # add the fireball to the parent scene
		fireball.set_fireball_direction(sign($Position2D.position.x) == 1)
		fireball.global_position = get_node("Position2D").global_position
	
	match current_action:
		ACTIONS.IDLE:
			if not is_sword_out:
				anim_player.play("idle")
			else:
				anim_player.play("idle_sword")
		ACTIONS.RUNNING:
			anim_player.play("run")
		ACTIONS.CROUCHING:
			anim_player.play("crouch")
		ACTIONS.SLIDING:
			anim_player.play("slide")
		ACTIONS.STANDING:
			anim_player.play("stand")
		ACTIONS.JUMPING:
			anim_player.play("jump")
		ACTIONS.FALLING:
			anim_player.play("fall")
		ACTIONS.ATTACKING:
			anim_player.play("attack_light")
		ACTIONS.CASTING:
			anim_player.play("cast")
			print("Casting")
		ACTIONS.SWORD_SEATH:
			anim_player.play("sword_seath")
			print("returning sword")
	

#warning-ignore:unused_argument
func _physics_process(delta):
#	velocity.y += GRAVITY * delta
	velocity.y += GRAVITY
	get_input()
	
	velocity = move_and_slide(velocity, FLOOR)  # move and slide calculates delta behind the scene

func _on_animation_finished():
	current_action = ACTIONS.IDLE
	var animation = anim_player.get_animation()
	if animation == "sword_seath":
		is_sword_out = false
#	pass

func _on_slide_timer_timeout():
	print("slide timer stopped")
	velocity.x = 0
	current_action = ACTIONS.STANDING
	get_node("slide_cooldown_timer").start()

func _on_sword_seath_timer_timeout():
	print("time to put sword back")
	current_action = ACTIONS.SWORD_SEATH
