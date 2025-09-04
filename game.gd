extends Node3D

@export var zombie_scene: PackedScene
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_location: PathFollow3D = $SpawnPath/SpawnLocation
@onready var player: CharacterBody3D = $Player

@export var max_zombies := 10
var zombies_spawned := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn_zombie() -> void:
	var zombie := zombie_scene.instantiate()
	
	# And give it a random offset.
	spawn_location.progress_ratio = randf()
	zombie.initialize(spawn_location.position, player)
	
	add_child(zombie)
	

func _on_spawn_timer_timeout() -> void:
	if zombies_spawned >= max_zombies:
		spawn_timer.stop()
		return
		
	print("timer timedout")
	spawn_zombie()
	zombies_spawned += 1
	
