extends Node2D
class_name Biome

@onready var player : CharacterBody2D = get_tree().get_first_node_in_group("Player")
@onready var BaseTexture := $BaseTexture 

var vp : SubViewport

# Called when the node enters the scene tree for the first time.
func _ready():
	vp = player.tire_vp
	


func _process(delta):
	var m = BaseTexture.material as ShaderMaterial
	

	if(is_instance_valid(player.tire_vp)):
		vp = player.tire_vp
		vp.size = BaseTexture.get_rect().size
		print(vp.size)
		m.set_shader_parameter("TireViewportTexture", vp.get_texture())
		

