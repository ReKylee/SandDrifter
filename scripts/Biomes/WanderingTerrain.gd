extends Node3D

@onready var chunks = $CollisionChunks
@onready var terrain := $Terrain as MeshInstance3D
@onready var timer := $Timer as Timer
@export var player : Node3D


@onready var _cellular2dNoise = terrain.get_surface_override_material(0).get_shader_parameter("_cellular2dNoise").noise as FastNoiseLite
@onready var _simplex3dNoise = terrain.get_surface_override_material(0).get_shader_parameter("_simplex3dNoise").noise as FastNoiseLite
@onready var Height_Dune = terrain.get_surface_override_material(0).get_shader_parameter("Height_Dune")
@onready var _cellular_height : Image = _cellular2dNoise.get_seamless_image(512, 512)
@onready var _simplex_height : Image = _simplex3dNoise.get_seamless_image(512, 512)

var player_pos : Vector3
var snap_step = 20
var div = 2243
var collidable_world_radius : float = 5


func _ready():
	
	
	
	initialize_collisions()
	
	timer.connect("timeout", snap)
	snap()



func spiral(pos : Vector2):
	if(abs(pos.x) <= abs(pos.y) && (pos.x != pos.y || pos.x >= 0)):
		pos.x += 1 if (pos.y >= 0) else -1
	else:
		pos.y += -1 if (pos.x >= 0) else 1
	return pos


func initialize_collisions():

	_cellular_height.resize(_cellular_height.get_width() / 2 + 1, _cellular_height.get_height() / 2 + 1)
	_simplex_height.resize(_simplex_height.get_width() / 2 + 1, _simplex_height.get_height() / 2 + 1)
	
	
	var pos : Vector2
	for i in collidable_world_radius*2:
		var chunk = TerrainChunkCollision.new(CalculateHeight)
		chunks.add_child(chunk)
		chunk.global_position = Vector3(pos.x, 0, pos.y) * div
		chunk.pos = pos
		chunk.create_collision()
		pos = spiral(pos)
	
	
	
func snap():
	
	player_pos = player.global_position.snapped(Vector3(snap_step, 0, snap_step))
	terrain.global_position.x = player_pos.x
	terrain.global_position.z = player_pos.z
	terrain.get_surface_override_material(0).set("shader_parameter/uv_offset", -Vector2(player_pos.x / div, player_pos.z / div))
	
	timer.start()

func CalculateHeight(uv : Vector2, offset : Vector2) -> float:
	#UV is pixel coords on texture
	uv -= offset
	var new_uv = Vector2(fposmod(uv.x, _simplex_height.get_width()), fposmod(uv.y, _simplex_height.get_width()))
	var SimplexNoise = _simplex_height.get_pixelv(new_uv).r * _simplex_height.get_width();
	var simplexed_uv = lerp(new_uv, Vector2(SimplexNoise, SimplexNoise), .1);
	var DunesWorleyNoise = _cellular_height.get_pixelv(simplexed_uv).r * Height_Dune * 2;
	return DunesWorleyNoise
