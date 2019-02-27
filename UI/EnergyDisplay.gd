extends Node2D

onready var tween_node = get_node("Tween")


#func _ready():
#	for node in get_children():
#		node.hide()

func update_energy_bar(value):
	tween_node.interpolate_property($energy_bar, 'value', $energy_bar.value, value, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween_node.start()
#	$energy_bar.value = value
#	for node in get_children():
#		node.show()