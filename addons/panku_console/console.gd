## Panku Console. Provide a runtime GDScript REPL so your can run any script expressions in your game!
##
## This class will be an autoload ([code] Console [/code] by default) if you enable the plugin. The basic idea is that you can run [Expression] based on an environment(or base instance) by [method execute]. You can view [code]default_env.gd[/code] to see how to prepare your own environment.
## [br]
## [br] What's more, you can...
## [br]
## [br] ● Send in-game notifications by [method notify]
## [br] ● Output something to the console window by [method output]
## [br] ● Manage widgets plans by [method add_widget], [method save_current_widgets_as], etc.
## [br] ● Lot's of useful expressions defined in [code]default_env.gd[/code].
##
## @tutorial:            https://github.com/Ark2000/PankuConsole
class_name PankuConsole extends CanvasLayer

## Emitted when the visibility (hidden/visible) of console window changes.
signal repl_visible_about_to_change(is_visible:bool)
signal repl_visible_changed(is_visible:bool)

# Global singleton name is buggy in Godot 4.0, so we get the singleton by path instead.
const SingletonName = "Console"
const SingletonPath = "/root/" + SingletonName

#Static helper classes
const Config = preload("res://addons/panku_console/components/config.gd")
const Utils = preload("res://addons/panku_console/components/utils.gd")

#Other classes, define classes here instead of using keyword `class_name` so that the global namespace will not be affected.
const ExporterRowUI = preload("res://addons/panku_console/components/exporter/row_ui.gd")
const JoystickButton = preload("res://addons/panku_console/components/exporter/joystick_button.gd")
const LynxWindow2 = preload("res://addons/panku_console/components/lynx_window2/lynx_window_2.gd")
const lynx_window_prefab = preload("res://addons/panku_console/components/lynx_window2/lynx_window_2.tscn")
const exp_key_mapper_prefab = preload("res://addons/panku_console/components/input_mapping/exp_key_mapper_2.tscn")
const monitor_prefab = preload("res://addons/panku_console/components/monitor/monitor_2.tscn")
const exporter_prefab = preload("res://addons/panku_console/components/exporter/exporter_2.tscn")

## The input action used to toggle console. By default it is KEY_QUOTELEFT.
var toggle_console_action:String

## If [code]true[/code], pause the game when the console window is active.
var pause_when_active:bool:
	set(v):
		pause_when_active = v
		is_repl_window_opened = is_repl_window_opened

var init_expression:String = ""

var mini_repl_mode = false:
	set(v):
		mini_repl_mode = v
		if is_repl_window_opened:
			_mini_repl.visible = v
			_full_repl.set_window_visibility(!v)

var is_repl_window_opened := false:
	set(v):
		repl_visible_about_to_change.emit(v)
		await get_tree().process_frame
		is_repl_window_opened = v
		if mini_repl_mode:
			_mini_repl.visible = v
		else:
			_full_repl.set_window_visibility(v)
		if pause_when_active:
			_full_repl.set_window_title_text("</> Panku REPL (Paused)")
		else:
			_full_repl.set_window_title_text("</> Panku REPL")
		get_tree().paused = pause_when_active and v
		repl_visible_changed.emit(v)
		if unified_visibility:
			w_manager.visible = v
		else:
			w_manager.visible = true

#this behavior will kepp all windows' visibility the same as developer conosle.
var unified_visibility := false;

@export var _resident_logs:Node
@export var _base_instance:Node
@export var _mini_repl:Node
@export var _full_repl:Node
@export var godot_log_monitor:Node
@export var output_overlay:Node
@export var w_manager:Node
@export var options:Node
@export var exp_key_mapper:Node
@export var exp_history_window:Node
@export var logger_window:Node
@export var logger_options:Node
@export var effect_crt:ColorRect

var _envs = {}
var _envs_info = {}
var _expression = Expression.new()

# The current scene root node, which will be updated automatically when the scene changes.
var _current_scene_root:Node

## Register an environment that run expressions.
## [br][code]env_name[/code]: the name of the environment
## [br][code]env[/code]: The base instance that runs the expressions. For exmaple your player node.
func register_env(env_name:String, env:Object):
	_envs[env_name] = env
#	output("[color=green][Info][/color] [b]%s[/b] env loaded!"%env_name)
	if env is Node:
		env.tree_exiting.connect(
			func(): remove_env(env_name)
		)
	if env.get_script():
		var env_info = Utils.extract_info_from_script(env.get_script())
		for k in env_info:
			var keyword = "%s.%s" % [env_name, k]
			_envs_info[keyword] = env_info[k]

## Return the environment object or [code]null[/code] by its name.
func get_env(env_name:String) -> Node:
	return _envs.get(env_name)

## Remove the environment named [code]env_name[/code]
func remove_env(env_name:String):
	if _envs.has(env_name):
		_envs.erase(env_name)
		for k in _envs_info.keys():
			if k.begins_with(env_name + "."):
				_envs_info.erase(k)
	#notify("[color=green][Info][/color] [b]%s[/b] env unloaded!"%env_name)

## Generate a notification
func notify(any) -> void:
	var text = str(any)
	_resident_logs.add_log(text)
	output(text)

func output(any) -> void:
	_full_repl.get_content().output(any)

#Execute an expression in a preset environment.
func execute(exp:String) -> Dictionary:
	return Utils.execute_exp(exp, _expression, _base_instance, _envs)

func get_available_export_objs() -> Array:
	var result = []
	for obj_name in _envs:
		var obj = _envs[obj_name]
		if !obj.get_script():
			continue
		var export_properties = Utils.get_export_properties_from_script(obj.get_script())
		if export_properties.is_empty():
			continue
		result.push_back(obj_name)
	return result

func add_exporter_window_by_expression(obj_expression:String, window_title := ""):
	var result = execute(obj_expression)
	var obj = null
	if result["failed"]:
		return
	obj = result["result"]
	if !(obj is Object):
		return
	var window:LynxWindow2 = add_exporter_window(obj, window_title)
	window.get_content().set_meta("content_type", "inspector")
	window.get_content().set_meta("content_data", {"expression": obj_expression})
	window.no_bookmark = false
	return window

func add_exporter_window(obj:Object, window_title := ""):
	if !obj.get_script():
		return

	var new_window:LynxWindow2 = lynx_window_prefab.instantiate()
	if window_title == "":
		new_window._title_btn.text = "Exporter (%s)" % str(obj)
	else:
		new_window._title_btn.text = window_title
	new_window._options_btn.hide()
	w_manager.add_child(new_window)
	var content = exporter_prefab.instantiate()
	new_window.set_content(content)
	content.setup(obj)
	new_window.centered()
	return new_window

func add_monitor_window(exp:String, update_interval:= 999999.0):
	var new_window:LynxWindow2 = lynx_window_prefab.instantiate()
	new_window._title_btn.text = exp
	new_window.no_bookmark = false
	var content = monitor_prefab.instantiate()
	content._update_exp = exp
	content._update_period = update_interval
	content.change_window_title_text.connect(
		func(text:String):
			new_window._title_btn.text = text
	)
	content.set_meta("content_type", "monitor")
	content.set_meta("content_data", {"expression": exp, "update_interval": update_interval})
	new_window._options_btn.pressed.connect(
		func():
			add_exporter_window(content, "Monitor Settings")
	)
	new_window.title_btn_clicked.connect(content.update_exp_i)
	w_manager.add_child(new_window)
	new_window.set_content(content)
	return new_window

func show_intro():
	output("[font_size=24][b][color=#478cbf]Panku Console[/color] ~ [color=#478cbf]version %s[/color][/b][/font_size]" % Utils.get_plugin_version())
	output("")
	output("All-in-One Godot 4 runtime debugging tool.")
	output("")
	output("[b][color=#478cbf]🌟Repo[/color][/b]: 🔗[url=https://github.com/Ark2000/PankuConsole]https://github.com/Ark2000/PankuConsole[/url]")
	output("")
	output("[b][color=#478cbf]❤️Contributors[/color][/b]: 🔗[url=https://github.com/Ark2000]Ark2000(Feo Wu)[/url], 🔗[url=https://github.com/scriptsengineer]scriptengineer(Rafael Correa)[/url], 🔗[url=https://github.com/winston-yallow]winston-yallow(Winston)[/url], 🔗[url=https://github.com/CheapMeow]CheapMeow[/url].")
	output("")
	output("> Tips: you can always access current scene root by `[b]current[/b]`.")
	output("")

func open_expression_key_mapper():
	exp_key_mapper.centered()
	exp_key_mapper.move_to_front()
	exp_key_mapper.show()

func open_expression_history():
	exp_history_window.centered()
	exp_history_window.move_to_front()
	exp_history_window.show()

func open_logger():
	logger_window.centered()
	logger_window.move_to_front()
	logger_window.show()

func _input(_e):
	if Input.is_action_just_pressed(toggle_console_action):
		is_repl_window_opened = !is_repl_window_opened

func _ready():
	assert(get_tree().current_scene != self, "Do not run this directly")

	show_intro()
	toggle_console_action = ProjectSettings.get("panku/toggle_console_action")
	
#	print(Config.get_config())
	_full_repl.hide()
	_mini_repl.hide()
	
	_full_repl.get_content().set_meta("content_type", "interactive_shell_main")
	logger_window.get_content().set_meta("content_type", "logger")

	_full_repl._options_btn.pressed.connect(
		func():
			add_exporter_window(options, "Settings")
	)

	_full_repl.window_closed.connect(
		func():
			is_repl_window_opened = false
	)
	
	logger_window._options_btn.pressed.connect(
		func():
			add_exporter_window(logger_options, "Logger Settings")
	)

	#check the action key
	#the open console action can be change in the export options of panku.tscn
	assert(InputMap.has_action(toggle_console_action), "Please specify an action to open the console!")

	#add info of base instance
	var env_info = Utils.extract_info_from_script(_base_instance.get_script())
	for k in env_info: _envs_info[k] = env_info[k]

	load_data()

	setup_scene_root_tracker()

func _notification(what):
	#quit event
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()

# always register the current scene root as `current`
func setup_scene_root_tracker():
	_current_scene_root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	register_env("current", _current_scene_root)
	create_tween().set_loops().tween_callback(
		func(): 
			var r = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
			if r != _current_scene_root:
				_current_scene_root = r
				register_env("current", _current_scene_root)
	).set_delay(0.1)

func load_data():
	#load configs
	var cfg = Config.get_config()

	init_expression = cfg.get(Utils.CFG_INIT_EXP, "")
	create_tween().tween_callback(
		func(): execute(init_expression)
	).set_delay(0.1)
	pause_when_active = cfg.get(Utils.CFG_PAUSE_WHEN_POPUP, false)
	mini_repl_mode = cfg.get(Utils.CFG_MINI_REPL_MODE, false)
	output_overlay.visible = cfg.get(Utils.CFG_OUTPUT_OVERLAY, true)
	output_overlay.modulate.a = cfg.get(Utils.CFG_OUTPUT_OVERLAY_ALPHA, 0.5)
	output_overlay.theme.default_font_size= cfg.get(Utils.CFG_OUTPUT_OVERLAY_FONT_SIZE, 14)
	_full_repl.get_content()._console_logs.set_font_size(cfg.get(Utils.CFG_REPL_OUTPUT_FONT_SIZE, 16))
	unified_visibility = cfg.get(Utils.CFG_UNIFIED_VISIBILITY, false)

	var blur_effect = cfg.get(Utils.CFG_WINDOW_BLUR_EFFECT, true)
	_full_repl.material.set("shader_parameter/lod", 4.0 if blur_effect else 0.0)

	var base_color = cfg.get(Utils.CFG_WINDOW_BASE_COLOR, Color(0, 0, 0, 0.7))
	_full_repl.material.set("shader_parameter/modulate", base_color)

	var shadow = cfg.get(Utils.CFG_OUTPUT_OVERLAY_FONT_SHADOW, false)
	output_overlay.set("theme_override_colors/font_shadow_color", Color.BLACK if shadow else null)

	var tween := create_tween()
	tween.tween_callback(
		func():
			var bookmarked_windows_data:Array = cfg.get(Utils.CFG_BOOKMARK_WINDOWS, [])
			# deserialize bookmarked windows
			var current_scene_file_path = get_tree().root.get_children()[-1].scene_file_path
			for data in bookmarked_windows_data:
				#bookmarked windows are only loaded in the same scene when saved.
				if current_scene_file_path != data["scene_file_path"]:
					continue
				var window:LynxWindow2
				var content_data = data.get("content_data", "")
				var content_type = data.get("content_type", "")
				if content_type == "inspector":
					window = add_exporter_window_by_expression(content_data["expression"], data["title"])
				elif content_type == "monitor":
					window = add_monitor_window(content_data["expression"], content_data["update_interval"])
				elif content_type == "interactive_shell_main":
					window = _full_repl
					is_repl_window_opened = true
				elif content_type == "logger":
					window = logger_window
					window.show()
				else:
					assert(false, "TODO")
				window.load_data(data)
			#clear current scene bookmarks
			bookmarked_windows_data = bookmarked_windows_data.filter(
				func(data): return data["scene_file_path"] != current_scene_file_path
			)
			cfg[Utils.CFG_BOOKMARK_WINDOWS] = bookmarked_windows_data
			Config.set_config(cfg)
	).set_delay(0.1)

func save_data():
	var cfg = Config.get_config()
	cfg[Utils.CFG_INIT_EXP] = init_expression
	cfg[Utils.CFG_PAUSE_WHEN_POPUP] = pause_when_active
	cfg[Utils.CFG_MINI_REPL_MODE] = mini_repl_mode
	cfg[Utils.CFG_WINDOW_BLUR_EFFECT] = _full_repl.material.get("shader_parameter/lod") > 0.0
	cfg[Utils.CFG_WINDOW_BASE_COLOR] = _full_repl.material.get("shader_parameter/modulate")
	cfg[Utils.CFG_OUTPUT_OVERLAY] = output_overlay.visible
	cfg[Utils.CFG_OUTPUT_OVERLAY_ALPHA] = output_overlay.modulate.a
	cfg[Utils.CFG_OUTPUT_OVERLAY_FONT_SIZE] = output_overlay.theme.default_font_size
	cfg[Utils.CFG_OUTPUT_OVERLAY_FONT_SHADOW] = output_overlay.get("theme_override_colors/font_shadow_color") != null
	cfg[Utils.CFG_REPL_OUTPUT_FONT_SIZE] = _full_repl.get_content()._console_logs.get_font_size()
	cfg[Utils.CFG_UNIFIED_VISIBILITY] = unified_visibility

	Config.set_config(cfg)
