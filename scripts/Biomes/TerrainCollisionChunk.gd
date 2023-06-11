extends StaticBody3D
class_name TerrainChunkCollision


var CollisionShape := CollisionShape3D.new()
var CollisionArea := Area3D.new()
var Sprite := Sprite3D.new()

var generated : bool = false
var height_function : Callable
var collisoin_decimation : int = 2
var size_in_pixels : Vector2 = Vector2(512, 512)

@export var generate : bool = false :
	set(value):
		generated = false
		create_collision()
		generate = false

var pos : Vector2
var img : Image 

func _init(f : Callable):
	height_function = f
	
	Sprite.axis = Vector3.AXIS_Y
	Sprite.pixel_size = 1
	Sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	Sprite.rotation_degrees.y = 180
	var area_col = CollisionShape3D.new()
	area_col.shape = SphereShape3D.new()
	area_col.shape.radius = 3
	CollisionArea.add_child(area_col)
	
	CollisionArea.collision_mask = 0
	CollisionArea.set_collision_layer_value(1, false)
	CollisionArea.set_collision_layer_value(4, true)
	
	add_child(CollisionShape)
	add_child(CollisionArea)
	add_child(Sprite)
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
	var float_array : PackedFloat32Array = []
	
	scale.x = 2243/size_in_pixels.x * collisoin_decimation
	scale.z = 2243/size_in_pixels.y * collisoin_decimation 
	
	
	var shap = HeightMapShape3D.new()
	CollisionShape.shape = shap
	shap.map_depth = size_in_pixels.y / collisoin_decimation + 1
	shap.map_width = size_in_pixels.x / collisoin_decimation + 1
	img = Image.create(shap.map_depth, shap.map_width, true, Image.FORMAT_RGBA8)
	for y in shap.map_depth:
		for x in shap.map_width:
			var h = height_function.bind(Vector2(x, y), pos).call()
			float_array.push_back( h )
			if(x < shap.map_width-1 && y < shap.map_depth-1):
				img.set_pixel(x, y, Color(h/400, h/400, h/400, 1))
	CollisionShape.shape.map_data = float_array
	
	Sprite.texture = ImageTexture.create_from_image(img)
	generated = true


