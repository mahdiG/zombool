extends Node3D

signal game_over()

const MAIN = preload("uid://ckxstxjr4a2p")

@export var zombie_scene: PackedScene
@export var max_zombies := 10

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
@onready var spawn_location: PathFollow3D = $SpawnPath/SpawnLocation
@onready var player: CharacterBody3D = $Player
@onready var fps_label: Label = $DebugStats/DebugContainer/FpsLabel
@onready var health_label: Label = $DebugStats/DebugContainer/HealthLabel
@onready var big_center_label: Label = $CenterContainer/BigCenterLabel
@onready var big_center_label_timer: Timer = $BigCenterLabelTimer

var is_game_over := false
var zombies_spawned := 0
var zombies_dead := 0
var current_round := 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.died.connect(_on_player_died)
	start_round()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
func start_round() -> void:
	big_center_label.text = "Round %d" % current_round
	big_center_label.visible = true
	big_center_label_timer.start()
	zombies_spawned = 0
	zombies_dead = 0
	max_zombies += 10
	enemy_spawn_timer.start()

func spawn_zombie() -> void:
	var zombie := zombie_scene.instantiate()
	
	# And give it a random offset.
	spawn_location.progress_ratio = randf()
	zombie.initialize(spawn_location.position, player)
	# call _on_zombie_died function when zombie's died signal is emitted
	zombie.died.connect(_on_zombie_died)
	
	add_child(zombie)
	

func exit_game_and_go_to_main_menu():
	game_over.emit()
	queue_free()
	

func _on_enemy_spawn_timer_timeout() -> void:
	if zombies_spawned >= max_zombies:
		enemy_spawn_timer.stop()
		return
		
	spawn_zombie()
	zombies_spawned += 1

func _on_player_took_damage(_old_health: int, new_health: int) -> void:
	health_label.text = "Health: %d" % new_health

func _on_zombie_died() -> void:
	zombies_dead += 1
	if zombies_dead == max_zombies:
		current_round += 1
		start_round()
		
func _on_player_died() -> void:
	is_game_over = true
	big_center_label.text = "You died!"
	big_center_label.visible = true
	enemy_spawn_timer.stop()
	big_center_label_timer.start()
	
func _on_big_center_label_timer_timeout() -> void:
	big_center_label.visible = false
	print("isGameOVer:" , is_game_over)
	if is_game_over:
		exit_game_and_go_to_main_menu()

func _on_pause_menu_exit() -> void:
	exit_game_and_go_to_main_menu()
