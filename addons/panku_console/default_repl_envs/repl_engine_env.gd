extends "res://addons/panku_console/default_repl_envs/repl_env.gd"

@onready var console:PankuConsole = get_node(PankuConsole.SingletonPath)

const _HELP_set_fullscreen = "Set [fullscreen / windowed] mode"
func set_fullscreen(b:bool):
	if b:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

const _HELP_toggle_fullscreen = "Toggle [fullscreen / windowed] mode"
var toggle_fullscreen:
	get:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

const _HELP_time_scale = "Equals to [color=green]Engine.time_scale[/color]"
func time_scale(val:float):
	Engine.time_scale = val

const _HELP_performance_info = "Show performance info"
var performance_info:
	get:
		return "FPS: %d | Mem: %.2fMB | Objs: %d" % [Engine.get_frames_per_second(), OS.get_static_memory_usage()/1048576.0, Performance.get_monitor(Performance.OBJECT_COUNT)]

const _HELP_snap_screenshot = "Snap a screenshot of current window"
var snap_screenshot:
	get:
		var image = get_viewport().get_texture().get_image()
		var time = str(int(Time.get_unix_time_from_system() * 1000.0))
		var file_name = "screenshot_%s.png" % time
		var path = "user://".path_join(file_name)
		var real_path = OS.get_user_data_dir().path_join(file_name)
		image.save_png(path)
		get_parent().notify("[b]Screenshot[/b] saved at [color=green][url=%s]%s[/url][/color]" % [real_path, real_path])

const _HELP_quit = "Quit application"
var quit:
	get:
		get_tree().quit()

const _HELP_show_os_report = "Display detailed OS report"
func show_os_report() -> void:
	console.output("Please wait, this may take a while...")
	await get_tree().create_timer(0.1).timeout
	var obj = load("res://addons/panku_console/components/os_report.gd").new()
	obj.inspect()
	var report =  "".join(obj.rtl)
	console.output(report)

# Currently godot can't toggle visibility of 2D collision shapes at runtime, this is a workaround.
# See https://github.com/godotengine/godot-proposals/issues/2072
const _HELP_toggle_2d_collision_shape_visibility = "Toggle visibility of 2D collision shapes, useful for debugging"
func toggle_2d_collision_shape_visibility() -> void:
	var tree := get_tree()
	tree.debug_collisions_hint = not tree.debug_collisions_hint

	# Traverse tree to call queue_redraw on instances of
	# CollisionShape2D and CollisionPolygon2D.
	var node_stack: Array[Node] = [tree.get_root()]
	while not node_stack.is_empty():
		var node: Node = node_stack.pop_back()
		if is_instance_valid(node):
			if node is CollisionShape2D or node is CollisionPolygon2D:
				node.queue_redraw()
			node_stack.append_array(node.get_children())

const _HELP_reload_current_scene = "Reload current scene"
func reload_current_scene() -> void:
	get_tree().reload_current_scene()
