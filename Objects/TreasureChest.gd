extends Area2D

export (int) var gold = 10
var is_open = false

func _ready():
	$gold_coin_emitter.emitting = false
	pass
	

func _on_TreasureChest_body_entered(body):
	if not is_open:
		if "Player" in body.name:
			$AnimatedSprite.play("open")
			body.update_gold(int(gold))
			

func _on_animation_finished():
	is_open = true
	$gold_coin_emitter.emitting = true
#	$gold_coin_emitter.show()
	$gold_coin_emitter_timer.start()


func _on_gold_coin_emitter_timer_timeout():
	$gold_coin_emitter.emitting = false
	$gold_coin_emitter.hide()
	$AnimatedSprite.stop()  # stop the animation
	$AnimatedSprite.set("frame", 1)  # set frame to empty chest
	
