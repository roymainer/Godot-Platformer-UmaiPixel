extends Node2D

onready var start_button = $MarginContainer/VBoxContainer/VBoxContainer2/start_button
onready var exit_button = $MarginContainer/VBoxContainer/VBoxContainer2/exit_button


func _ready():
	start_button.grab_focus()  # start button will be focused at the start of the scene
	
	
func _physics_process(delta):
	if start_button.is_hovered():
		start_button.grab_focus()
	if exit_button.is_hovered():
		exit_button.grab_focus()


func _on_start_button_pressed():
	get_tree().change_scene("res://StageOne.tscn")


func _on_exit_button_pressed():
	get_tree().quit()
