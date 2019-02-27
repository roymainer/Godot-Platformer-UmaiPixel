extends "res://Enemies/Enemy.gd"

const COL_SHAPE_POS_X = -4
const COL_SHAPE_POS_Y = 3


func animate():
	
	var pos = Vector2(0,0)
	$AnimatedSprite.set("position", pos)
	if has_node("CollisionShape2D"):
#		if get_node("CollisionShape2D") != null:
		$CollisionShape2D.set("position", Vector2(COL_SHAPE_POS_X*self.direction, COL_SHAPE_POS_Y))

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
			pos.x = -3
			pos.y = 0#-6
			$AnimatedSprite.set("position", pos)
			$CollisionShape2D.set("position", Vector2(-10*self.direction, 6))
		
		ACTIONS.HURT:
			anim_player.play("hurt")
		
		ACTIONS.DIE:
			anim_player.play("die")
	

#func _on_visibility_timer_timeout():
#	pass # Replace with function body.
