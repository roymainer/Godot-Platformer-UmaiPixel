extends Area2D

export(String, FILE, "*.tscn") var target_stage  # the editor will expect for a string file name with .tscn extension

func _ready():
	pass
	

func _on_body_entered(body):
	print("body entered")
	if "Player" in body.name:
		get_tree().change_scene(target_stage)
	
