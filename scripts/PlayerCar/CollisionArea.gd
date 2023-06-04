extends Area3D


var current_chunk : TerrainChunkCollision
var moving_chunk : TerrainChunkCollision
@onready var radius : float = $CollisionShape3D.shape.radius

func _process(delta):
	var bodies = get_overlapping_areas()
	print(bodies)
	if Engine.get_physics_frames() % 10 == 0:
		for chunk in bodies:
			
			if(chunk.global_position.distance_to(global_position) < radius):
				current_chunk = chunk.get_parent()
			else:
				chunk.disable()
		if(is_instance_valid(current_chunk)):
			if(current_chunk.is_disabled()):
				current_chunk.enable()
			else:
				current_chunk.create_collision()
