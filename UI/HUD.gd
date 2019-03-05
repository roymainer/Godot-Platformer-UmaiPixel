extends CanvasLayer

var fireball_icon = preload("res://Assets/UI/fireball_icon.png")
var iceball_icon = preload("res://Assets/UI/iceball_icon.png")
var heal_icon = preload("res://Assets/UI/heal.png")

onready var tween_node = get_node("Tween")

func _ready():
	$MarginContainer/VBoxContainer/HBoxContainer2/SpellBarRect/RichTextLabel.text = "Fireball"
	$MarginContainer/VBoxContainer/HBoxContainer3/GoldBar/RichTextLabel.text = "0"

func update_healthbar(value):
	tween_node.interpolate_property($MarginContainer/VBoxContainer/HBoxContainer/HealthBarRect/HealthBar, 'value', 
									$MarginContainer/VBoxContainer/HBoxContainer/HealthBarRect/HealthBar.value, value, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.start()
#	$MarginContainer/HBoxContainer/TextureRect/HealthBar.value = value
	
func update_energybar(value):
	tween_node.interpolate_property($MarginContainer/VBoxContainer/HBoxContainer2/EnergyBarRect/EnergyBar, 'value', 
									$MarginContainer/VBoxContainer/HBoxContainer2/EnergyBarRect/EnergyBar.value, value, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.start()
#	$MarginContainer/VBoxContainer/TextureRect2/EnergyBar.value = value
#	print("energy bar val: " + str($MarginContainer/VBoxContainer/TextureRect2/EnergyBar.value))

func update_armorbar(value):
	tween_node.interpolate_property($MarginContainer/VBoxContainer/HBoxContainer/ArmorBarRect/ArmorBar, 'value', 
									$MarginContainer/VBoxContainer/HBoxContainer/ArmorBarRect/ArmorBar.value, value, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.start()
#	$MarginContainer/VBoxContainer/TextureRect3/ArmorBar.value = value

func _on_Player_spell_changed(spell):
	print("spell: " +str(spell))
	match spell:
		0:
			$MarginContainer/VBoxContainer/HBoxContainer2/SpellBarRect/icon_sprite.texture = fireball_icon
			$MarginContainer/VBoxContainer/HBoxContainer2/SpellBarRect/RichTextLabel.text = "Fireball"
		1:
			$MarginContainer/VBoxContainer/HBoxContainer2/SpellBarRect/icon_sprite.texture = iceball_icon
			$MarginContainer/VBoxContainer/HBoxContainer2/SpellBarRect/RichTextLabel.text = "Frostball"
		2: 
			$MarginContainer/VBoxContainer/HBoxContainer2/SpellBarRect/icon_sprite.texture = heal_icon
			$MarginContainer/VBoxContainer/HBoxContainer2/SpellBarRect/RichTextLabel.text = "Heal"
	$AnimationPlayer.play("scale_spell_icon_name")
	
func _on_Player_gold_changed(value):
	$MarginContainer/VBoxContainer/HBoxContainer3/GoldBar/RichTextLabel.text = str(value)
	$AnimationPlayer.play("scale_gold")


func _on_Player_level_changed(lvl):
	var new_string = str("LV.", str(lvl))
	$MarginContainer/VBoxContainer/HBoxContainer3/ExperienceRect/Level.text = new_string
	#TODO: add size tween


func _on_Player_xp_changed(value):
	tween_node.interpolate_property($MarginContainer/VBoxContainer/HBoxContainer3/ExperienceRect/ExperienceBar, 'value', 
									$MarginContainer/VBoxContainer/HBoxContainer3/ExperienceRect/ExperienceBar.value, value, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.start()
	$AnimationPlayer.play("scale_level")
