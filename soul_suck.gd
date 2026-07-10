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
	var camera_transform: Transform3D = player_camera.global_transform
	
	# Transform the ghost's world position into the camera's local coordinate space
	# In Godot's camera space: -Z is Forward, +Z is Backward, +X is Right, -X is Left
	var local_direction: Vector3 = camera_transform.basis.inverse() * (ghost_position - camera_transform.origin)
	
	# Calculate the horizontal angle on the XZ plane relative to the camera's view direction
	var horizontal_angle: float = atan2(local_direction.x, -local_direction.z)
	
	# Shift angle forward by half a segment (PI / 8) to center coordinate axes within sectors
	var normalized_angle: float = fposmod(horizontal_angle + (PI / 8.0), TAU)
	var raw_sector_index: int = int(normalized_angle / (PI / 4.0))
	
	# Remap the raw 3D local slices to perfectly match your clockwise GhostDirection enum values:
	# Index 0 (Front) -> maps to GhostDirection.TOP (6)
	# Index 2 (Right) -> maps to GhostDirection.RIGHT (0)
	# Index 4 (Back)  -> maps to GhostDirection.BOTTOM (2)
	# Index 6 (Left)  -> maps to GhostDirection.LEFT (4)
	var aligned_sector_index: int = (raw_sector_index + 6) % 8
	
	return aligned_sector_index as GhostDirection

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
