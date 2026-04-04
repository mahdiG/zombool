extends CharacterBody3D

signal died()

@export var speed := 5.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

var health := 100
var target_hero: CharacterBody3D
var isAttackOnCooldown := false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	navigation_agent.target_position = target_hero.position
	var current_location := global_transform.origin
	var next_location := navigation_agent.get_next_path_position()
	var new_velocity := current_location.direction_to(next_location) * speed
	
	if navigation_agent.avoidance_enabled:
		# This only works if avoidance is enablenavigationd
		navigation_agent.set_velocity(new_velocity)
	else:
		velocity = new_velocity
	
	move_and_slide()

func initialize(spawn_position: Vector3, player: CharacterBody3D) -> void:
	target_hero = player
	position = spawn_position

func _on_navigation_agent_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity

func _on_navigation_agent_target_reached() -> void:
	#print("reached target")
	if !isAttackOnCooldown:
		attack()

func attack() -> void:
	target_hero.take_damage(20)
	#print("zombie attacked")
	isAttackOnCooldown = true
	attack_cooldown_timer.start()
	

func take_damage(amount: int) -> void:
	health = health - amount
	if health <= 0:
		die()

func die() -> void:
	print("zombie died")
	died.emit()
	queue_free()

func _on_attack_cooldown_timer_timeout() -> void:
	isAttackOnCooldown = false
