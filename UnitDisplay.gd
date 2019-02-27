extends Node2D


func _ready():
	for node in get_children():
		node.hide()

func update_healthbar(value):
	$health_bar.value = value
	for node in get_children():
		node.show()