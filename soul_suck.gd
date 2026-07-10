extends ColorRect

enum GhostDirection {
	RIGHT,
	BOTTOM_RIGHT,
	BOTTOM,
	BOTTOM_LEFT,
	LEFT,
	TOP_LEFT,
	TOP,
	TOP_RIGHT
}

@export var player_camera: Camera3D
@export var max_tracking_distance: float = 12.0

# Internal intensity trackers
var target_intensities: PackedFloat32Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var current_intensities: PackedFloat32Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sync_intensities_to_shader()

func _process(delta: float) -> void:
	if not player_camera:
		return
		
	evaluate_all_enemy_distances()
	interpolate_intensities(delta)
	sync_intensities_to_shader()

# Scans the entire game world for objects in the "enemies" group and measures their proximity
func evaluate_all_enemy_distances() -> void:
	clear_target_intensities()
	
	var active_enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var camera_global_position: Vector3 = player_camera.global_transform.origin
	
	for enemy in active_enemies:
		var spatial_enemy := enemy as Node3D
		if not spatial_enemy or not is_instance_valid(spatial_enemy):
			continue
			
		var distance_to_enemy: float = camera_global_position.distance_to(spatial_enemy.global_position)
		
		# Ignore enemies that are outside our spooky aura radius
		if distance_to_enemy >= max_tracking_distance:
			continue
			
		# Calculate strength: Closer = higher intensity (scaled 0.0 to 1.0)
		var closeness_intensity: float = 1.0 - (distance_to_enemy / max_tracking_distance)
		var directional_sector: GhostDirection = calculate_spatial_direction_sector(spatial_enemy.global_position)
		
		# If multiple enemies are in the same direction, prioritize the closest threat
		target_intensities[directional_sector] = max(target_intensities[directional_sector], closeness_intensity)

# Calculates the precise 45-degree pie slice mapping 3D target coordinates to the viewport
func calculate_spatial_direction_sector(ghost_position: Vector3) -> GhostDirection:
	if player_camera.is_position_behind(ghost_position):
		return calculate_behind_camera_fallback_sector(ghost_position)
		
	var screen_pixel_position: Vector2 = player_camera.unproject_position(ghost_position)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_center := Vector2(viewport_size.x / 2.0, viewport_size.y / 2.0)
	
	var vector_from_center: Vector2 = screen_pixel_position - screen_center
	var angle_radians: float = vector_from_center.angle()
	
	# Shift angle forward by half a segment (PI / 8) to center coordinate axes within sectors
	var normalized_angle: float = fposmod(angle_radians + (PI / 8.0), TAU)
	var sector_index: int = int(normalized_angle / (PI / 4.0))
	
	return (sector_index % 8) as GhostDirection

# Safety math evaluating fallback edges if a ghost attacks from directly behind player viewport
func calculate_behind_camera_fallback_sector(ghost_position: Vector3) -> GhostDirection:
	var camera_transform: Transform3D = player_camera.global_transform
	var local_direction: Vector3 = camera_transform.basis.inverse() * (ghost_position - camera_transform.origin)
	
	if local_direction.x < 0.0:
		return GhostDirection.LEFT if local_direction.y > -0.5 else GhostDirection.BOTTOM_LEFT
	else:
		return GhostDirection.RIGHT if local_direction.y > -0.5 else GhostDirection.BOTTOM_RIGHT

# Smoothly steps values toward target boundaries to ensure fluid visual transitions
func interpolate_intensities(delta: float) -> void:
	var responsiveness_speed: float = 5.0 # How fast the shader reacts to movement
	
	for index in range(8):
		var current: float = current_intensities[index]
		var target: float = target_intensities[index]
		
		current_intensities[index] = move_toward(current, target, responsiveness_speed * delta)

# Dispatches array blocks safely down into the GLSL engine uniform pipeline
func sync_intensities_to_shader() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material:
		shader_material.set_shader_parameter("directional_intensities", current_intensities)

func clear_target_intensities() -> void:
	for index in range(8):
		target_intensities[index] = 0.0
