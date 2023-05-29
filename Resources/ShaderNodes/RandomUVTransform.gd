@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeHexagonalGrid

func _init():
	
	set_input_port_default_value(1, Vector2.ZERO)
	set_input_port_default_value(2, 0.8)
	set_input_port_default_value(3, 1.2)
	set_input_port_default_value(4, -180.0)
	set_input_port_default_value(5, 180.0)

func _get_name() -> String:
	return "RandomUVTransform"

func _get_category() -> String:
	return "UV"

func _get_description() -> String:
	return "Randomly transforms a given UV"

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_input_port_count() -> int:
	return 6

func _get_input_port_name(port: int):
	match port:
		0:
			return "uv"
		1:
			return "randomSeed"
		2:
			return "scaleMin"
		3:
			return "scaleMax"
		4:
			return "rotationMin"
		5:
			return "rotationMax"

func _get_input_port_type(port: int):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		2:
			return VisualShaderNode.PORT_TYPE_SCALAR
		3:
			return VisualShaderNode.PORT_TYPE_SCALAR
		4:
			return VisualShaderNode.PORT_TYPE_SCALAR
		5:
			return VisualShaderNode.PORT_TYPE_SCALAR

func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(port: int) -> String:
	return "uv"

func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_global_code(mode):
	var code : String = preload("res://Resources/ShaderNodes/RandomUVTransform.gdshaderinc").code
	return code

func _get_code(input_vars, output_vars, mode, type):
	var uv = "UV"
	var seed = Vector2.ZERO
	if input_vars[0]:
		uv = input_vars[0]
	if input_vars[1]:
		seed = input_vars[1]
	return "%s = _random_transformUV(%s, %s, %s, %s, %s, %s);" % [
			output_vars[0], uv, seed, input_vars[2], input_vars[3], input_vars[4], input_vars[5]]
