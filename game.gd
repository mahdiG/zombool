extends Node3D

@export var zombie_scene: PackedScene
@export var max_zombies := 10

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_location: PathFollow3D = $SpawnPath/SpawnLocation
@onready var player: CharacterBody3D = $Player
@onready var fps_label: Label = $DebugStats/DebugContainer/FpsLabel
@onready var health_label: Label = $DebugStats/DebugContainer/HealthLabel

var zombies_spawned := 0
var zombies_dead := 0
var current_round := 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func spawn_zombie() -> void:
	var zombie := zombie_scene.instantiate()
	
	# And give it a random offset.
	spawn_location.progress_ratio = randf()
	zombie.initialize(spawn_location.position, player)
	# call _on_zombie_died function when zombie's died signal is emitted
	zombie.died.connect(_on_zombie_died)
	
	add_child(zombie)
	

func _on_spawn_timer_timeout() -> void:
	if zombies_spawned >= max_zombies:
		spawn_timer.stop()
		return
		
	#print("timer timedout")
	spawn_zombie()
	zombies_spawned += 1

func _on_player_took_damage(_old_health: int, new_health: int) -> void:
	health_label.text = "Health: %d" % new_health

func _on_zombie_died() -> void:
	zombies_dead += 1
	if zombies_dead == max_zombies:
		print("finished round")
