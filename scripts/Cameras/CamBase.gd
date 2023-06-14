extends Node3D

# Generic constants
const QUARTER_CIRCLE := 0.25 * TAU
const CLOCKWISE_CIRCLE := -TAU
const ABSURD_VECTOR2 := Vector2.INF
const HALF_VECTOR2 := Vector2.ONE * 0.5
const MIRRORED_X := Vector2(-1.0, 1.0)
const MIRRORED_Y := Vector2(1.0, -1.0)
# Internal normalizations to target sane defaults at 1
const ZOOM_STRENGTH_NORMALIZATION := 0.05
const MOUSE_DRAG_STRENGTH_NORMALIZATION := 0.1
const MOUSE_MOVE_STRENGTH_NORMALIZATION := 0.00005
const ACTION_MOVE_STRENGTH_NORMALIZATION := 0.1

@onready var pcam = $PhantomCamera3D as PhantomCamera3D

@export_group("Actions")
## Coefficient for the horizontal intent of movement actions.
## Use a negative value to invert the direction of the horizontal intents.
@export var action_strength_x := 1.0
@export var action_strength_y := 1.0
@export var action_zoom_in := 'ui_up'
@export var action_zoom_out := 'ui_down'
@export var action_right := 'ui_right'
@export var action_left := 'ui_left'


@export_group("Orbit")
@export var orbit_strength := 1.0


@export_group("Zoom")
@export var zoom_enabled := true
@export var zoom_strength := 1.0
@export var zoom_minimum := 1.0
@export var zoom_maximum := 100.0
@export_range(0.0, 1.0, 0.000001) var zoom_inertia_threshold := 0.0001
@export var zoom_in_dampening := 0.0  # 25.0 works well as a value here


@export_group("Inertia")
## Coefficient applied to all lateral (non-zoom) intents.
@export var inertia_strength := 1.0
@export_range(0.0, 1.0, 0.000001) var inertia_threshold := 0.0001
## Fraction of inertia lost on each frame.
@export_range(0.0, 1.0, 0.0001) var friction := 0.07:
	set(value):
		friction = value
		recompute_lubricant_efficiency()

var action_enabled : bool = true
var _lubricantEfficiency := 1.0
var _dragInertia := Vector2.ZERO
var _zoomInertia := 0.0

func _ready():
	recompute_lubricant_efficiency()

func _process(delta):
	process_actions(delta)
	process_zoom(delta)
	process_drag_inertia(delta)
	process_zoom_inertia(delta)
	
func process_actions(delta: float):
	if action_enabled:
		var intent := delta * ACTION_MOVE_STRENGTH_NORMALIZATION
		if Input.is_action_pressed(action_left):
			add_inertia(Vector2(
				intent
				* Input.get_action_strength(action_left)
				* self.action_strength_x
				,
				0.0
			))
		if Input.is_action_pressed(action_right):
			add_inertia(Vector2(
				intent
				* Input.get_action_strength(action_right)
				* self.action_strength_x
				* -1.0
				,
				0.0
			))

func process_zoom(delta: float):
	if self.zoom_enabled:
		var intent := self.zoom_strength * ZOOM_STRENGTH_NORMALIZATION
		if Input.is_action_pressed(self.action_zoom_in):
			add_zoom_inertia(intent * -1.0)
		if Input.is_action_pressed(self.action_zoom_out):
			add_zoom_inertia(intent)

func process_zoom_inertia(delta: float):
	# This whole function is … bouerk.  Please share your improvements!
	var cpl := get_distance_to_target()
	if abs(_zoomInertia) > zoom_inertia_threshold:
		if cpl < zoom_minimum:
			if _zoomInertia > 0.0:
				_zoomInertia *= float(max(0, 1 - (1.333 * (zoom_minimum - cpl) / zoom_minimum)))
			_zoomInertia = _zoomInertia + 0.1 * (zoom_minimum - cpl) / zoom_minimum
		if cpl > zoom_maximum:
			_zoomInertia -= 0.09 * exp((cpl - zoom_maximum) * 3 + 1) * (cpl - zoom_maximum) * (cpl - zoom_maximum)
		apply_zoom(_zoomInertia)
		apply_zoom_friction()
	else:
		_zoomInertia = 0.0

func process_drag_inertia(delta: float):
	var inertia := _dragInertia.length()
	if inertia > self.inertia_threshold:
		apply_rotation_from_tangent(_dragInertia * inertia_strength)
		apply_drag_friction()
	else:
		_dragInertia.x = 0
		_dragInertia.y = 0

func apply_zoom(amount: float):
	get_viewport().get_camera_3d().size += amount

func apply_rotation_from_tangent(tangent: Vector2):
	var up: Vector3
	up = get_camera_up()
	var upQuat := Quaternion(up, tangent.x * CLOCKWISE_CIRCLE)
	var rotatedTransform := Transform3D(upQuat) * get_transform()
	set_transform(rotatedTransform)

func get_mouse_position() -> Vector2:
	return (
		get_viewport().get_mouse_position()
		/
		get_viewport().get_visible_rect().size
	)

func add_zoom_inertia(inertia: float):
	if zoom_in_dampening > 0.0 and inertia > 0.0:
		var delta := float(abs(get_distance_to_target() - zoom_minimum))
		var brake := pow(zoom_in_dampening, -1.0 * delta + 1.0) + 1.0
		inertia /= brake
	_zoomInertia += inertia


func add_inertia(inertia: Vector2):
	_dragInertia += inertia * self.orbit_strength

func recompute_lubricant_efficiency():
	_lubricantEfficiency = 1.0 - self.friction

func apply_drag_friction():
	_dragInertia *= _lubricantEfficiency
	
func apply_zoom_friction():
	_zoomInertia *= _lubricantEfficiency

func get_camera_up() -> Vector3:  # in parent's space
	return (get_transform().basis * Vector3.UP).normalized()

func get_camera_right() -> Vector3:  # in parent's space
	return (get_transform().basis * Vector3.RIGHT).normalized()

func get_distance_to_target() -> float:
	return get_viewport().get_camera_3d().size

