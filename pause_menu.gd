extends VBoxContainer

signal exit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# PROCESS_MODE_ALWAYS ensures this menu continues to process inputs 
	# and logic even when the rest of the game scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event):
	print("pause menu input event: ", event)
	if event.is_action_pressed("option"):
		if get_tree().paused == true:
			resume()
		else:
			pause()

func pause():
	get_tree().paused = true
	self.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func resume():
	get_tree().paused = false
	self.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	


func _on_resume_button_pressed() -> void:
	resume()

func _on_exit_button_pressed() -> void:
	resume()
	exit.emit()
