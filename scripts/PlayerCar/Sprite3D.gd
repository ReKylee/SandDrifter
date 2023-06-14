extends Sprite3D


var camera : Camera3D
func _ready():
	camera = get_viewport().get_camera_3d()
	
func _process(delta):
	var camera_pos_2d = Vector2(camera.global_position.x, camera.global_position.z).normalized()
	var angle = Vector2.DOWN.angle_to(camera_pos_2d)
	var camera_dir_to_sprite = int(floor((angle / (PI / 8))))
	camera_dir_to_sprite = (camera_dir_to_sprite + 8) % 16
	print(camera_dir_to_sprite)
	frame = camera_dir_to_sprite
