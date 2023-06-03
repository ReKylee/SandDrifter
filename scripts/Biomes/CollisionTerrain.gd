extends CollisionShape3D

@export var terrain : MeshInstance3D
@export var _cellular2dNoise : NoiseTexture2D 
@export var _simplex3dNoise : NoiseTexture2D 

var _cellular_height : Image
var _simplex_height : Image
var Height_Dune 
var Height_Detail

var collisoin_decimation := 1

var material : ShaderMaterial 

var offsetUVs : Vector2 
@export var offsetUv : Vector2 = Vector2(-13.458, 13.458)


@export var reverse : bool = false
@export var generate : bool : 
	set(value):
		create_collision()
@export_range(-1, 1) var hM : float = 1

const TEXEL_SIZE = 1.0 / 512.0

func _ready():
	material = terrain.get_surface_override_material(0)
	
	await _cellular2dNoise.changed
	
	scale.x =  2243 * TEXEL_SIZE
	scale.z =  2243 * TEXEL_SIZE
	create_collision()
	#get_parent().start_generating_collision = true
	
func create_collision():
	
	var float_array : PackedFloat32Array = []
	
	Height_Dune = material.get_shader_parameter("Height_Dune")
	
	_cellular_height = _cellular2dNoise.get_image()
	_simplex_height = _simplex3dNoise.get_image()
	
	_cellular_height.resize(_cellular_height.get_width()/ collisoin_decimation + 1,  _cellular_height.get_height()/ collisoin_decimation + 1)
	_simplex_height.resize(_simplex_height.get_width()/ collisoin_decimation + 1,  _simplex_height.get_height()/ collisoin_decimation + 1)
	
	var shap = HeightMapShape3D.new()
	shape = shap
	shap.map_depth = _cellular_height.get_height()
	shap.map_width = _cellular_height.get_width()
	for y in _cellular_height.get_height():
		for x in _cellular_height.get_width():
			var c = Vector2(x, y)
			var h = CalculateHeight(c) 
			float_array.push_back(h)
	
	if(reverse):
		float_array.reverse()
		
	shape.map_data = float_array
	
	#create_collision_anchors
	


func CalculateHeight(uv : Vector2) -> float:
	
	var SimplexNoise = _simplex_height.get_pixel(uv.x, uv.y).r;
	#This is bullshit
	var simplexed_uv = Vector2(SimplexNoise, SimplexNoise) * .1 + uv * (1.0-.1);
	var DunesWorleyNoise = _cellular_height.get_pixel(simplexed_uv.x, simplexed_uv.y).r * Height_Dune ;
	return DunesWorleyNoise
	


