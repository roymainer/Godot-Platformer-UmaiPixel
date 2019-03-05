extends KinematicBody2D

enum ACTION {
	IDLE, 
	RUN, 
	SLIDE, 
	STAND, 
	CROUCH, 
	JUMP, 
	DOUBLE_JUMP,
	FALL,
	WALL_SLIDE,
	ATTACK, 
	AIR_ATTACK1,
	CAST,
	CAST_LOOP,
	SWORD_SEATH,
	HURT,
	DEAD
	}

#warning-ignore:unused_class_variable
var actions_dict = {
	ACTION.IDLE : "idle",
	ACTION.RUN : "run",
	ACTION.SLIDE : "slide",
	ACTION.STAND : "stand",
	ACTION.CROUCH : "crouch",
	ACTION.JUMP: "jump",
	ACTION.DOUBLE_JUMP: "double_jump",
	ACTION.FALL: "fall",
	ACTION.WALL_SLIDE: "wall_slide",
	ACTION.ATTACK: "attack",
	ACTION.AIR_ATTACK1: "air_attack1",
	ACTION.CAST: "cast",
	ACTION.CAST_LOOP: "cast_loop",
	ACTION.SWORD_SEATH: "sword_seath",
	ACTION.HURT: "hurt",
	ACTION.DEAD: "dead"
	}
	

# Spells
enum SPELLS {
	FIREBALL, 
	FROSTBALL,
	HEAL
	}
	
var spells_dict = {
	SPELLS.FIREBALL: {"name": "Fireball", "energy": 20},
	SPELLS.FROSTBALL: {"name": "Frostball", "energy": 20},
	SPELLS.HEAL: {"name": "Heal", "energy": 40}
}

const FIREBALL = preload("res://Effects/Fireball.tscn")
const FROSTBALL = preload("res://Effects/Frostball.tscn")
const HEAL = preload("res://Effects/Heal.tscn")


onready var anim_player = get_node("AnimatedSprite")
onready var camera = get_node("Camera2D")
onready var enemy_detector = get_node("enemy_detector")

# Constants
const MAX_SPEED = 120
const GRAVITY = 10
const ACCELERATION = 50
const JUMP_POWER = -250
const FLOOR = Vector2(0, -1)

const ATTACK_LIGHT = 25
const ATTACK_HEAVY = 50

# Camera
const CAMERA_SPEED = 1  # how fast the camera offsets when crouching
const CAMERA_OFFSET = 40  

# Attributes
export (int) var max_health = 100
export (int) var max_energy = 100
export (int) var energy_regen_rate = 5
export (int) var max_armor = 100
var health = max_health
var energy = max_energy
var armor = max_armor
var gold = 0
var experience = 0
var level = 1

var velocity = Vector2()

var current_action = null
var current_action_name = null
var current_spell = SPELLS.FIREBALL
var is_sword_out = false
var can_double_jump = true  # this is used for double jump
var double_jumping = false  # this is used for double jump
var is_dead = false
var is_hurt = false
var is_attacking = false
#var is_casting = false
var is_loop_casting = false

# debug variables
#var prev_animation = null
#var prev_frame = null

# Signals
signal health_changed
signal energy_changed
signal armor_changed
signal spell_changed
signal gold_changed
signal xp_changed
signal level_changed


func _ready():
#	get_node("wall_slide_dirt").hide()
	health = max_health
	emit_signal("health_changed", health * 100 / max_health)

#warning-ignore:unused_argument
func _physics_process(delta):
	
	if not is_dead:
		velocity.y += GRAVITY
		_input_manager()
		_actions_manager()
		_offset_camera()
		velocity = move_and_slide(velocity, FLOOR)  # move and slide calculates delta behind the scene
		
		current_action_name = actions_dict[current_action]
		print(current_action_name)
		print(str(velocity.x))

func _input_manager():
	
	if is_loop_casting:
		return
	
	_check_horizontal_keys()  
	_check_vertical_keys()
	_check_action_keys()
	_check_tunneling()  # if in tunnel, can't do much except crouch or slide
	_check_sword_seath()
	_check_idle()
	
func _update_direction(right = true):
	var direction = sign($player_cast_position_2d.position.x)  # get current player direction
	if direction == -1 and right:  # if facing left, and player is pressing right move button
		$player_cast_position_2d.position.x *= -1  # invert the position of the "shooting cursor"
#		$wall_slide_dirt.position.x *= -1  # flip the wall slide dirt effect as well
		enemy_detector.cast_to.x *= -1
	elif direction == 1 and not right:
		$player_cast_position_2d.position.x *= -1  # invert the x position of the shooting "cursor"
#		$wall_slide_dirt.position.x *= -1  # flip the wall slide dirt effect as well
		enemy_detector.cast_to.x *= -1

func _check_horizontal_keys():
	
	if current_action == ACTION.ATTACK or current_action == ACTION.CAST:
		return
	elif current_action == ACTION.SLIDE or current_action == ACTION.CROUCH and int(abs(velocity.x)) > 0:
		velocity.x = int(lerp(velocity.x, 0, 0.005))
		return
		
	var horizontal_move = false  # horizontal move flag
	
	if Input.is_action_pressed("ui_right"):
		horizontal_move = true
		velocity.x = min(velocity.x + ACCELERATION, MAX_SPEED)  # update horizontal velocity to move right
		anim_player.flip_h = false
		_update_direction(true)
		
	elif Input.is_action_pressed("ui_left"):
		horizontal_move = true
		velocity.x = max(velocity.x - ACCELERATION, -MAX_SPEED) # update horizontal velocity to move left
		anim_player.flip_h = true
		_update_direction(false)
	else:
		velocity.x = int(lerp(velocity.x, 0, 0.2))  # slow down speed gradually (20% per frame)
		
	if is_on_floor():# and current_action != ACTION.SLIDE:
		if horizontal_move:
			current_action = ACTION.RUN  # set action to running
#		elif ACTIONS.find(current_action) == -1:
#			current_action = ACTION.IDLE
	
func _check_vertical_keys():
	
	if is_on_floor():
		if Input.is_action_pressed("ui_down"):
			if abs(velocity.x) < MAX_SPEED/2:
				current_action = ACTION.CROUCH
			else:
				current_action = ACTION.SLIDE
			
		elif Input.is_action_just_released("ui_down"):
			if not ($tunnel_detector.is_colliding() or $tunnel_detector2.is_colliding()):
				if current_action == ACTION.SLIDE:
					current_action = ACTION.STAND
				else:
					current_action = ACTION.IDLE
		
		
		if Input.is_action_just_pressed("ui_up"):
			if not ($tunnel_detector.is_colliding() or $tunnel_detector2.is_colliding()):
				# if not sliding/crouching
				velocity.y = JUMP_POWER
				double_jumping = false
				
	elif Input.is_action_just_pressed("ui_up") and double_jumping == false:
		velocity.y = JUMP_POWER
		double_jumping = true
		
	if velocity.y < 0 and current_action != ACTION.AIR_ATTACK1:
		if not double_jumping:
			current_action = ACTION.JUMP
		else:
			current_action = ACTION.DOUBLE_JUMP
	elif velocity.y > 0 and not is_on_floor() and current_action != ACTION.AIR_ATTACK1 and current_action != ACTION.CAST:
		if is_on_wall():
			current_action = ACTION.WALL_SLIDE
			velocity.y = lerp(velocity.y, 0, 0.05)
		else:
			current_action = ACTION.FALL
		
func _check_action_keys():
	
	""" Attack """
	if Input.is_action_just_pressed("attack") and current_action != ACTION.CAST:
		is_sword_out = true
		$Timers/sword_seath_timer.stop()
		if is_on_floor():
#			if abs(velocity.x) > 0:
#				velocity.x -= sign($player_cast_position_2d.position.x)*MAX_SPEED/2  # slow down when attacking
			current_action = ACTION.ATTACK
		else:
			current_action = ACTION.AIR_ATTACK1
	
	""" Casting """
	if Input.is_action_just_pressed("cast") and current_action != ACTION.ATTACK: 
		current_action = ACTION.CAST
		_cast()
			
	""" Change Spell """
	if Input.is_action_just_pressed("next_spell"):
		current_spell += 1
		if current_spell > len(SPELLS):  # check overflow
			current_spell = 0  # first spell
		emit_signal("spell_changed", current_spell)
	
	if Input.is_action_just_pressed("prev_spell"):
		current_spell -= 1
		if current_spell < 0:  # check overflow
			current_spell = len(SPELLS) - 1  # last spell
		emit_signal("spell_changed", current_spell)

func _check_tunneling():
	if is_on_floor():
		if $tunnel_detector.is_colliding() and $tunnel_detector2.is_colliding():
			if abs(velocity.x) < MAX_SPEED/2:
				current_action = ACTION.CROUCH
			else:
				current_action = ACTION.SLIDE
#	elif is_on_floor() and ACTIONS.find(current_action) != -1:
#		current_action = ACTION.IDLE

func _check_idle():
	var exp_actions = [ACTION.ATTACK,  ACTION.CAST, ACTION.CAST_LOOP, ACTION.SWORD_SEATH, ACTION.STAND, ACTION.CROUCH]
	if is_on_floor():
		if abs(velocity.x) < 2:
			if exp_actions.find(current_action) == -1:
				if ($tunnel_detector.is_colliding() or $tunnel_detector2.is_colliding()):
					current_action = ACTION.CROUCH
				else:
					current_action = ACTION.IDLE

func _check_sword_seath():
	if current_action == ACTION.IDLE and is_sword_out:
		if $Timers/sword_seath_timer.time_left == 0:
			$Timers/sword_seath_timer.start()

func _actions_manager():
	
#	print("current action: "+ str(current_action))
	
	match current_action:
		ACTION.IDLE:
			if not is_sword_out:
				anim_player.play("idle")
			else:
				anim_player.play("idle_sword")
			$collision_shape_stand.disabled = false
			$collision_shape_crouch.disabled = true
			$collision_shape_slide.disabled = true
		ACTION.RUN:
			anim_player.play("run")
			$collision_shape_stand.disabled = false
			$collision_shape_crouch.disabled = true
			$collision_shape_slide.disabled = true
		ACTION.CROUCH:
			anim_player.play("crouch")
			$collision_shape_stand.disabled = true
			$collision_shape_crouch.disabled = false
			$collision_shape_slide.disabled = true
		ACTION.SLIDE:
			anim_player.play("slide")
			$collision_shape_stand.disabled = true
			$collision_shape_crouch.disabled = true
			$collision_shape_slide.disabled = false
		ACTION.STAND:
			anim_player.play("stand")
			$collision_shape_stand.disabled = false
			$collision_shape_crouch.disabled = true
			$collision_shape_slide.disabled = true
		ACTION.JUMP:
			anim_player.play("jump")
		ACTION.DOUBLE_JUMP:
			anim_player.play("air_flip")
		ACTION.FALL:
			anim_player.play("fall")
		ACTION.WALL_SLIDE:
			anim_player.play("wall_slide")
#			get_node("wall_slide_dirt").show()
		ACTION.ATTACK:
			anim_player.play("attack_light")
			_attack()
		ACTION.AIR_ATTACK1:
			anim_player.play("air_attack_1")
		ACTION.CAST:
			anim_player.play("cast")
		ACTION.CAST_LOOP:
			anim_player.play("cast_loop")
			if $Timers/cast_loop_timer.time_left == 0:
				$Timers/cast_loop_timer.start()
		ACTION.SWORD_SEATH:
			anim_player.play("sword_seath")
		ACTION.HURT:
			anim_player.play("hurt")
		ACTION.DEAD:
			anim_player.play("die")

func _on_animation_finished():
	
	if $Timers/cast_loop_timer.time_left > 0:
		return
		
	var animation = anim_player.get_animation()
	if animation == "sword_seath":
		is_sword_out = false
		current_action = ACTION.IDLE
	elif animation == "flip":
		double_jumping = false
	elif animation == "attack_light":
		current_action = ACTION.IDLE
		is_attacking = false
	elif animation == "air_attack_1":
		current_action = ACTION.FALL
		is_attacking = false
	elif animation == "hurt":
		is_hurt = false
		if health == 0:
			_dead()
	elif animation == "cast":
		if is_loop_casting:
			current_action = ACTION.CAST_LOOP
		else:
#			is_casting = false
			current_action = ACTION.IDLE
	elif animation == "stand":
		current_action = ACTION.IDLE

func _offset_camera():
	if Input.is_action_pressed("ui_down") and is_on_floor():
		camera.offset.y += CAMERA_SPEED
		camera.offset.y = clamp(camera.offset.y, 0, CAMERA_OFFSET)
	else:
		camera.offset.y -= CAMERA_SPEED * 2
		camera.offset.y = clamp(camera.offset.y, 0, CAMERA_OFFSET)
#	print("camera offset y :" +str(camera.offset.y))


func _attack():
	
	var animation = anim_player.animation
	var frame = anim_player.frame
	
	if enemy_detector.is_colliding() and not is_attacking:
		if (animation == "attack_light" and frame == 2) or (animation == "air_attack_1" and frame == 1):
			var collider = enemy_detector.get_collider()
	#		if "Enemy" in collider.name:
			if collider.has_method("hit"):
				
				is_attacking = true  # mark the flag to not hit twice
				
				match current_action:
					ACTION.ATTACK:
						collider.hit(ATTACK_LIGHT)
					ACTION.AIR_ATTACK1:
						collider.hit(ATTACK_LIGHT)
			
func hit(damage):
	health -= damage
	health = clamp(health, 0, max_health)
	emit_signal("health_changed", health * 100 / max_health)
	is_hurt = true
	current_action = ACTION.HURT
	if anim_player.get_animation() == "hurt":
		anim_player.set("frame", 0)
#	if health == 0:
#		dead()

func _cast():
#	if is_casting:
#		return
	
	var spell = null
	var energy_cost =  spells_dict[current_spell]["energy"]
	var spell_global_position = null
	
	if energy_cost > self.energy:
		# if spell requires more energy than the player has, return
		# TODO: change the color of the energy bar to red and back
		return		
	
	# instance spell and change action
	if current_spell == SPELLS.FIREBALL or current_spell == SPELLS.FROSTBALL:
		if current_spell == SPELLS.FIREBALL:
			spell = FIREBALL.instance()
		else:
			spell = FROSTBALL.instance()
		spell.set_spell_direction(sign($player_cast_position_2d.position.x) == 1)
		spell_global_position =  get_node("player_cast_position_2d").global_position
	
	elif current_spell == SPELLS.HEAL:
		if not is_on_floor():
			return
		spell = HEAL.instance()
		health += spell.get_health()
		health = clamp(health, 0, max_health)
		emit_signal("health_changed", health)
		spell_global_position = get_node("player_base_position_2d").global_position
		is_loop_casting = true
	
	get_parent().add_child(spell)  # add the spell to the parent scene	
	spell.global_position = spell_global_position
	if abs(velocity.x) > 0:
		velocity.x -= sign($player_cast_position_2d.position.x)*MAX_SPEED/2  # slow down when casting
		
	# update player energy
	energy -= energy_cost  
	energy = clamp(energy, 0, max_energy)
	emit_signal("energy_changed", energy * 100 / max_energy)
	
#	is_casting = true
	current_action = ACTION.CAST
	
func _dead():
	is_dead = true
	velocity = Vector2(0,0)
	current_action = ACTION.DEAD
	$crouch_collision_shape.disabled = true
	$stand_collision_shape.disabled = true
	$Timers/death_timer.start()



func _on_sword_seath_timer_timeout():
#	print("time to put sword back")
	current_action = ACTION.SWORD_SEATH

func _on_death_timer_timeout():
#warning-ignore:return_value_discarded
	get_tree().change_scene("res://TitleScreen.tscn")

func _on_screen_exited():
#warning-ignore:return_value_discarded
#	get_tree().change_scene("res://TitleScreen.tscn")
	pass


func _on_cast_loop_timer_timeout():
#	is_casting = false
	is_loop_casting = false  # disable all casting flags
#	current_action = ACTION.IDLE
	# eliminate the spell effect (particle)
	var spell = get_parent().get_node("Heal")
	spell.queue_free()


func _on_energy_regen_timer_timeout():
	energy += energy_regen_rate
	energy = clamp(energy, 0, max_energy)
	emit_signal("energy_changed", energy)


func update_gold(amount):
	gold += amount
	emit_signal("gold_changed", gold)


func _on_enemy_dead(xp):
	experience += xp
	var next_level = pow(10, level+1)
	if experience >= next_level:
		experience = experience - pow(10, level+1)
		level += 1
		emit_signal("level_changed", level)
	emit_signal("xp_changed", experience * 100 / pow(10, level+1))
