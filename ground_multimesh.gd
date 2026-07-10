@tool
extends MultiMeshInstance3D

@export var flower_mesh_node: MeshInstance3D
@export var terrain_mesh_node: MeshInstance3D
@export var terrain_mask_image: Texture2D
@export var target_flower_count: int = 1000

func _ready() -> void:
	if target_flower_count > 0:
		generate_scattered_environment()

func generate_scattered_environment() -> void:
	if not is_configuration_valid():
		return

	initialize_multimesh_resource()

	var mask_image_data = terrain_mask_image.get_image()
	var valid_spawn_positions = find_valid_spawn_positions(mask_image_data)
	
	apply_transforms_to_multimesh(valid_spawn_positions)

func is_configuration_valid() -> bool:
	if flower_mesh_node == null or flower_mesh_node.mesh == null:
		push_error("Invalid or missing flower mesh node.")
		return false
	if terrain_mesh_node == null or terrain_mesh_node.mesh == null:
		push_error("Missing terrain mesh node. Need this to automatically calculate map size.")
		return false
	if terrain_mask_image == null:
		push_error("Missing terrain mask texture.")
		return false
	return true

func initialize_multimesh_resource() -> void:
	var new_multimesh = MultiMesh.new()
	new_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_multimesh.mesh = flower_mesh_node.mesh
	multimesh = new_multimesh

func find_valid_spawn_positions(image_data: Image) -> Array[Vector3]:
	var spawned_positions: Array[Vector3] = []
	var attempts_made: int = 0
	var maximum_attempts: int = target_flower_count * 10
	
	# Automatically get the terrain's exact boundaries and size
	var terrain_bounding_box: AABB = terrain_mesh_node.get_aabb()

	while spawned_positions.size() < target_flower_count and attempts_made < maximum_attempts:
		attempts_made += 1
		var random_uv_coordinate = Vector2(randf(), randf())

		if is_position_allowed_by_mask(random_uv_coordinate, image_data):
			var horizontal_position = calculate_horizontal_position(random_uv_coordinate, terrain_bounding_box)
			var final_surface_position = calculate_surface_height(horizontal_position, terrain_bounding_box)
			
			if final_surface_position != Vector3.ZERO:
				spawned_positions.append(final_surface_position)

	return spawned_positions

func is_position_allowed_by_mask(uv_coordinate: Vector2, image_data: Image) -> bool:
	var pixel_x = int(uv_coordinate.x * image_data.get_width())
	var pixel_y = int(uv_coordinate.y * image_data.get_height())
	var pixel_color = image_data.get_pixel(pixel_x, pixel_y)

	return pixel_color.r > 0.5

func calculate_horizontal_position(uv_coordinate: Vector2, bounding_box: AABB) -> Vector3:
	var terrain_global_position = terrain_mesh_node.global_position
	var terrain_size = bounding_box.size
	
	# Map the 0.0 - 1.0 UV range directly onto the mesh's physical bounding box edges
	var x_position = terrain_global_position.x + bounding_box.position.x + (uv_coordinate.x * terrain_size.x)
	var z_position = terrain_global_position.z + bounding_box.position.z + (uv_coordinate.y * terrain_size.z)
	
	# Start the raycast slightly higher than the highest point of the terrain mesh
	var ray_start_y = terrain_global_position.y + bounding_box.end.y + 10.0
	
	return Vector3(x_position, ray_start_y, z_position)

func calculate_surface_height(ray_start_position: Vector3, bounding_box: AABB) -> Vector3:
	var physics_space = get_world_3d().direct_space_state
	
	# Fire the ray straight down past the lowest point of the mesh
	var ray_depth = bounding_box.size.y + 20.0
	var ray_end_position = ray_start_position + Vector3.DOWN * ray_depth
	
	var ray_query = PhysicsRayQueryParameters3D.create(ray_start_position, ray_end_position)
	var ray_intersection = physics_space.intersect_ray(ray_query)
	
	if ray_intersection:
		return ray_intersection.position
	return Vector3.ZERO

func apply_transforms_to_multimesh(positions: Array[Vector3]) -> void:
	multimesh.instance_count = positions.size()
	
	for index in range(positions.size()):
		var random_rotation = randf_range(0.0, PI * 2.0)
		var instance_transform = Transform3D().rotated(Vector3.UP, random_rotation)
		instance_transform.origin = positions[index]
		
		multimesh.set_instance_transform(index, instance_transform)
