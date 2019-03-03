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
	WALL_SLIDING,
	ATTACKING, 
	AIR_ATTACK1,
	CASTING,
	CAST_LOOP,
	SWORD_SEATH,
	HURT,
	DEAD
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
onready var stand_col_shape = get_node("stand_collision_shape")
onready var camera = get_node("Camera2D")
onready var enemy_detector = get_node("enemy_detector")

# Constants
const SPEED = 120
const GRAVITY = 10
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
var current_spell = SPELLS.FIREBALL
var is_sword_out = false
var can_double_jump = true  # this is used for double jump
var double_jumping = false  # this is used for double jump
var is_dead = false
var is_hurt = false
var is_casting = false
var is_loop_casting = false

# debug
var animation = null
var frame = null
var iterations = null

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


func get_input():
	
	if is_loop_casting:
		return
		
	""" RUNNING """
	if current_action != ACTIONS.ATTACKING and current_action != ACTIONS.CASTING:
		if Input.is_action_pressed("ui_right"):
			velocity.x = SPEED  # update horizontal velocity to move right
			anim_player.flip_h = false
			if sign($player_cast_position_2d.position.x) == -1: 
				$player_cast_position_2d.position.x *= -1  # invert the x position of the shooting "cursor"
#				$wall_slide_dirt.position.x *= -1  # flip the wall slide dirt effect as well
				enemy_detector.cast_to.x *= -1
			if is_on_floor():
				current_action = ACTIONS.RUNNING  # set action to running
				 
		elif Input.is_action_pressed("ui_left"):
			velocity.x = -SPEED
			anim_player.flip_h = true
			if sign($player_cast_position_2d.position.x) == 1:
				$player_cast_position_2d.position.x *= -1  # invert the x position of the shooting "cursor"
#				$wall_slide_dirt.position.x *= -1  # flip the wall slide dirt effect as well
				enemy_detector.cast_to.x *= -1
			if is_on_floor():
				current_action = ACTIONS.RUNNING
		else:
			velocity.x = 0
			if is_on_floor() == true and current_action != ACTIONS.ATTACKING and current_action != ACTIONS.SWORD_SEATH and not is_hurt:
				current_action = ACTIONS.IDLE
				var sword_timer = $Timers/sword_seath_timer
				if is_sword_out and sword_timer.time_left == 0:
#					print("starting sword seath timer")
					sword_timer.start()
				
		""" CROUCH and SLIDE """
		if Input.is_action_pressed("ui_down") and is_on_floor():
			if velocity.x == 0:
				current_action = ACTIONS.CROUCHING
			elif $Timers/slide_cooldown_timer.time_left == 0:
				current_action = ACTIONS.SLIDING
				var slide_timer = $Timers/slide_timer
				if slide_timer.time_left == 0:
#					print("starting slide timer")
					slide_timer.start()
			
			stand_col_shape.disabled = true
#			print("stand collision shape disabled")
			
		elif is_on_floor() and not $tunnel_detector.is_colliding():
			stand_col_shape.disabled = false
#			print("stand collision shape enabled")
#		
		if Input.is_action_just_released("ui_down"):
			$Timers/slide_timer.stop()
			$Timers/slide_cooldown_timer.stop()
			
			
		""" JUMPING """
		if Input.is_action_just_pressed("ui_up") and current_action != ACTIONS.SLIDING:
			if is_on_floor():
				velocity.y = JUMP_POWER
				double_jumping = false
				can_double_jump = true
			elif not is_on_floor() and can_double_jump:
				velocity.y = JUMP_POWER
				double_jumping = true
				can_double_jump = false
				
		if velocity.y < 0 and current_action != ACTIONS.AIR_ATTACK1:
			if not double_jumping:
				current_action = ACTIONS.JUMPING
			else:
				current_action = ACTIONS.DOUBLE_JUMPING
		elif velocity.y > 0 and not is_on_floor() and current_action != ACTIONS.AIR_ATTACK1 and not $tunnel_detector.is_colliding():
			if is_on_wall():
				current_action = ACTIONS.WALL_SLIDING
			else:
				current_action = ACTIONS.FALLING
		
	""" Normal Attacking """
	if Input.is_action_just_pressed("attack") and current_action != ACTIONS.CASTING: # and not is_attacking and is_on_floor():
		is_sword_out = true
		$Timers/sword_seath_timer.stop()
		if is_on_floor():
			if abs(velocity.x) > 0:
				velocity.x -= sign($player_cast_position_2d.position.x)*SPEED/2  # slow down when attacking
			current_action = ACTIONS.ATTACKING
		else:
			current_action = ACTIONS.AIR_ATTACK1
		attack()
		
		
	""" Casting """
	if Input.is_action_just_pressed("cast") and current_action != ACTIONS.ATTACKING: # and not is_attacking:
		cast()
	
	if $tunnel_detector.is_colliding() and is_on_floor():
		if velocity.x != 0:
			current_action = ACTIONS.SLIDING
		else:
			current_action = ACTIONS.CROUCHING
			
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
			
#	if current_action != ACTIONS.WALL_SLIDING:
#		$wall_slide_dirt.hide()
	
#	if enemy_detector.is_colliding():
#		var collider = enemy_detector.get_collider()
#		if collider.name == "Enemy":
#			print("colliding with enemy")
	
func animate():
	
#	print("current action: "+ str(current_action))
	
	match current_action:
		ACTIONS.IDLE:
			if not is_sword_out:
				anim_player.play("idle")
			else:
				anim_player.play("idle_sword")
		ACTIONS.RUNNING:
			anim_player.play("run")
#			print("run")
		ACTIONS.CROUCHING:
			anim_player.play("crouch")
#			print("crouch")
#			camera.offset.y += CAMERA_SPEED
#			clamp(camera.offset.y, CAMERA_OFFSET, camera.limit_bottom)
		ACTIONS.SLIDING:
			anim_player.play("slide")
#			print("slide")
		ACTIONS.STANDING:
			anim_player.play("stand")
#			print("stand")
		ACTIONS.JUMPING:
			anim_player.play("jump")
#			print("jump")
		ACTIONS.DOUBLE_JUMPING:
			anim_player.play("air_flip")
#			print("double jump")
		ACTIONS.FALLING:
			anim_player.play("fall")
#			print("fall")
		ACTIONS.WALL_SLIDING:
			anim_player.play("wall_slide")
#			get_node("wall_slide_dirt").show()
		ACTIONS.ATTACKING:
			anim_player.play("attack_light")
		ACTIONS.AIR_ATTACK1:
			anim_player.play("air_attack_1")
		ACTIONS.CASTING:
			anim_player.play("cast")
		ACTIONS.CAST_LOOP:
			anim_player.play("cast_loop")
			if $Timers/cast_loop_timer.time_left == 0:
				$Timers/cast_loop_timer.start()
		ACTIONS.SWORD_SEATH:
			anim_player.play("sword_seath")
		ACTIONS.HURT:
			anim_player.play("hurt")
		ACTIONS.DEAD:
			anim_player.play("die")

func offset_camera():
	if Input.is_action_pressed("ui_down") and is_on_floor():
		camera.offset.y += CAMERA_SPEED
		camera.offset.y = clamp(camera.offset.y, 0, CAMERA_OFFSET)
	else:
		camera.offset.y -= CAMERA_SPEED * 2
		camera.offset.y = clamp(camera.offset.y, 0, CAMERA_OFFSET)
#	print("camera offset y :" +str(camera.offset.y))

#warning-ignore:unused_argument
func _physics_process(delta):
	
#	var pos2d_position = $player_cast_position_2d.get("position")
#	var pos2d_global_position = $player_cast_position_2d.global_position
#	print("pos2d_pos: " + str(pos2d_position))
#	print("pos2d_global_pos: " + str(pos2d_global_position))

	if not is_dead:
	#	velocity.y += GRAVITY * delta
		velocity.y += GRAVITY
		get_input()
		animate()
		offset_camera()
		velocity = move_and_slide(velocity, FLOOR)  # move and slide calculates delta behind the scene
		
#		if get_slide_count() > 0:
#			for i in range(get_slide_count()):
#				if "Enemy" in get_slide_collision(i).collider.name:
#					# if collided with enemy body
#					dead()

		# make sure the player doesn't stuck
		if animation != $AnimatedSprite.animation:
			animation = $AnimatedSprite.animation
			frame = $AnimatedSprite.frame
			iterations = 0
		elif frame != $AnimatedSprite.frame:
			iterations = 0
		if animation == $AnimatedSprite.animation and frame == $AnimatedSprite.frame and iterations == 1:
			current_action = ACTIONS.IDLE
		
			

func attack():
	if enemy_detector.is_colliding():
		var collider = enemy_detector.get_collider()
#		if "Enemy" in collider.name:
		if collider.has_method("hit"):
			match current_action:
				ACTIONS.ATTACKING:
					collider.hit(ATTACK_LIGHT)
				ACTIONS.AIR_ATTACK1:
					collider.hit(ATTACK_LIGHT)
			
func hit(damage):
	health -= damage
	health = clamp(health, 0, max_health)
	emit_signal("health_changed", health * 100 / max_health)
	is_hurt = true
	current_action = ACTIONS.HURT
	if anim_player.get_animation() == "hurt":
		anim_player.set("frame", 0)
#	if health == 0:
#		dead()

func cast():
	if is_casting:
		return
	
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
#		var spell_position = spell.get("position")
#		var spell_global_position = spell.global_position
#		print("spell_pos: " + str(spell_position))
#		print("spell_global_pos: " +str(spell_global_position))
	
	elif current_spell == SPELLS.HEAL:
		if not is_on_floor():
			return
		spell = HEAL.instance()
		health += spell.get_health()
		health = clamp(health, 0, max_health)
		emit_signal("health_changed", health)
		spell_global_position = get_node("player_base_position_2d").global_position
#		spell.global_position.y += stand_col_shape.get('shape').get('extents').y  # fix the position
		is_loop_casting = true
	
	get_parent().add_child(spell)  # add the spell to the parent scene	
	spell.global_position = spell_global_position
	if abs(velocity.x) > 0:
		velocity.x -= sign($player_cast_position_2d.position.x)*SPEED/2  # slow down when casting
		
	# update player energy
	energy -= energy_cost  
	energy = clamp(energy, 0, max_energy)
	emit_signal("energy_changed", energy * 100 / max_energy)
	
	is_casting = true
	current_action = ACTIONS.CASTING
	
func dead():
	is_dead = true
	velocity = Vector2(0,0)
	current_action = ACTIONS.DEAD
	$crouch_collision_shape.disabled = true
	$stand_collision_shape.disabled = true
	$Timers/death_timer.start()

func _on_animation_finished():
	if $Timers/cast_loop_timer.time_left > 0:
		return
	current_action = ACTIONS.IDLE
	var animation = anim_player.get_animation()
	if animation == "sword_seath":
		is_sword_out = false
	elif animation == "flip":
		double_jumping = false
	elif animation == "air_attack_1":
		current_action = ACTIONS.FALLING
	elif animation == "hurt":
		is_hurt = false
		if health == 0:
			dead()
	elif animation == "cast":
		if is_loop_casting:
			current_action = ACTIONS.CAST_LOOP
		else:
			is_casting = false
#	pass

func _on_slide_timer_timeout():
#	print("slide timer stopped")
	velocity.x = 0
	current_action = ACTIONS.STANDING
	$Timers/slide_cooldown_timer.start()

func _on_sword_seath_timer_timeout():
#	print("time to put sword back")
	current_action = ACTIONS.SWORD_SEATH

func _on_death_timer_timeout():
	get_tree().change_scene("res://TitleScreen.tscn")


func _on_screen_exited():
	get_tree().change_scene("res://TitleScreen.tscn")


func _on_cast_loop_timer_timeout():
	is_casting = false
	is_loop_casting = false  # disable all casting flags
	current_action = ACTIONS.IDLE
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
	if experience >= pow(10, level+1):
		level += 1
		experience = experience - pow(10, level+1)
		emit_signal("level_changed", level)
	emit_signal("xp_changed", experience * 100 / pow(10, level+1))
