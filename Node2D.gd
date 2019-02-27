extends Node2D
var string = "air_attack_1"

func _ready():
	if string.find("attack") > -1:
		print("yes")