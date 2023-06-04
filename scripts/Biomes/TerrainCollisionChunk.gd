extends StaticBody3D
class_name TerrainChunkCollision


var CollisionShape := CollisionShape3D.new()
var CollisionArea := Area3D.new()
var generated : bool = false
var collisoin_decimation : int = 2
var height_function : Callable
var size_in_pixels : Vector2 = Vector2(513, 513)
@export var generate : bool = false :
	set(value):
		create_collision()
		generate = false
var pos : Vector2

func _init(f : Callable):
	height_function = f
	
	
	var area_col = CollisionShape3D.new()
	area_col.shape = SphereShape3D.new()
	area_col.shape.radius = 3
	CollisionArea.add_child(area_col)
	
	CollisionArea.collision_mask = 0
	CollisionArea.set_collision_layer_value(1, false)
	CollisionArea.set_collision_layer_value(4, true)
	
	add_child(CollisionShape)
	add_child(CollisionArea)
	disable()
	
func disable():
	CollisionShape.disabled = true
func enable():
	CollisionShape.disabled = false
func is_disabled():
	return CollisionShape.disabled
func create_collision():
	if(generated):
		return
	CollisionShape.rotation_degrees.y = 180
	CollisionShape.position = Vector3(-0.5, 0, -0.5)
	var float_array : PackedFloat32Array = []

	scale.x = 2243/size_in_pixels.x * collisoin_decimation
	scale.z = 2243/size_in_pixels.y * collisoin_decimation
	
	var shap = HeightMapShape3D.new()
	CollisionShape.shape = shap
	shap.map_depth = size_in_pixels.y / collisoin_decimation + 1
	shap.map_width = size_in_pixels.x / collisoin_decimation + 1
	for y in shap.map_depth:
		for x in shap.map_width:
			float_array.push_back( height_function.bind(Vector2(x, y), pos).call() )
	
	CollisionShape.shape.map_data = float_array
	
	generated = true


