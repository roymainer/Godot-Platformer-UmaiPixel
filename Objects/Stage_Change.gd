extends Area2D

export(String, FILE, "*.tscn") var target_stage  # the editor will expect for a string file name with .tscn extension

func _on_Stage_Change_body_entered(body):
	if "Player" in body.name:
			get_tree().change_scene(target_stage)
