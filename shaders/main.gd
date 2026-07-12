extends Node

const game_scene = preload("uid://gow0dapv2vfr")

@onready var main_menu: Node = $MainMenu
@onready var play_button: Button = $MainMenu/ButtonsContainer/PlayButton
@onready var exit_button: Button = $MainMenu/ButtonsContainer/ExitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _input(event: InputEvent):
	print("main input event: ", event)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_play_button_pressed() -> void:
	#get_tree().change_scene_to_packed(game_scene)
	main_menu.visible = false
	var game_instance := game_scene.instantiate()
	game_instance.game_over.connect(_on_game_over)
	get_tree().root.add_child(game_instance)
	
func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_game_over() -> void:
	main_menu.visible = true
