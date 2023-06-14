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
var collision_decimation : float = 2

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
	

	
	_cellular_height.resize(round(_cellular_height.get_width() / collision_decimation + 1), round(_cellular_height.get_height() / collision_decimation + 1))
	_simplex_height.resize(round(_simplex_height.get_width() / collision_decimation + 1), round(_simplex_height.get_height() / collision_decimation + 1))
	
	var pos : Vector2
	for i in collidable_world_radius*4:
		var chunk = TerrainChunkCollision.new(CalculateHeight)
		chunks.add_child(chunk)
		chunk.global_position = Vector3(pos.x, 0, pos.y) * div
		chunk.pos = pos
		chunk.collisoin_decimation = collision_decimation
		chunk.create_collision()
		chunk.show()
		pos = spiral(pos)
	
	
func snap():
	
	player_pos = player.global_position.snapped(Vector3(snap_step, 0, snap_step))
	terrain.global_position.x = player_pos.x
	terrain.global_position.z = player_pos.z
	terrain.get_surface_override_material(0).set("shader_parameter/uv_offset", -Vector2(player_pos.x / div, player_pos.z / div))
	
	timer.start()

func CalculateHeight(uv : Vector2, _offset : Vector2) -> float:
	
	var SimplexNoise : float = _simplex_height.get_pixelv(uv).r * float(_simplex_height.get_width());
	var amountx : float = smoothstep(0.0, 1.0, sin(uv.x * PI/_cellular_height.get_width())*.1)
	var amounty : float = smoothstep(0.0, 1.0, sin(uv.y * PI/_cellular_height.get_height())*.1)
	var simplexed_uv_x = lerp(uv.x, SimplexNoise, amountx)
	var simplexed_uv_y = lerp(uv.y, SimplexNoise, amounty)
	var simplexed_uv := Vector2(simplexed_uv_x, simplexed_uv_y)
	
	var DunesWorleyNoise : float = _cellular_height.get_pixelv(simplexed_uv).r * float(Height_Dune * 2);
	return DunesWorleyNoise
