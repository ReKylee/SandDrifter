extends Node3D


@onready var terrain := $Terrain as MeshInstance3D
@onready var terrain_collision := $TerrainCollision as CollisionShape3D
@onready var timer := $Timer as Timer
@export var player : Node3D

var player_pos : Vector3
var snap_step = 20
var div = 2243

var start_generating_collision : bool

func _ready():
	timer.connect("timeout", snap)
	snap()

func snap():
	
	player_pos = player.global_position.snapped(Vector3(snap_step, 0, snap_step))
	#terrain.global_position.x = player_pos.x
	#terrain.global_position.z = player_pos.z
	#terrain.get_surface_override_material(0).set("shader_parameter/uv_offset", -Vector2(player_pos.x / div, player_pos.z / div))
	
	#terrain_collision.global_position.x = player_pos.x
	#terrain_collision.global_position.z = player_pos.z
	terrain_collision.offsetUVs = -Vector2(player_pos.x / div, player_pos.z / div)
	if(start_generating_collision):
		terrain_collision.create_collision()
	timer.start()
	
