extends Node3D

@onready var play_button: Button = $ButtonsContainer/PlayButton
@onready var exit_button: Button = $ButtonsContainer/ExitButton
const GAME = preload("uid://gow0dapv2vfr")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(GAME)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
