@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeRandomUVTransform

func _init():
	
	set_input_port_default_value(1, 1.0)
	set_input_port_default_value(2, Vector3(2, 2, 2))
	set_input_port_default_value(3, Vector2.ZERO)
	set_input_port_default_value(4, Vector2.ZERO)
	set_input_port_default_value(5, Vector2.ZERO)


func _get_name() -> String:
	return "HexagonalGrid"

func _get_category() -> String:
	return "Shapes"

func _get_description() -> String:
	return "Hex Grid"

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_VECTOR_3D

func _get_input_port_count() -> int:
	return 6

func _get_input_port_name(port: int):
	match port:
		0:
			return "uv"
		1:
			return "hex size"
		2:
			return "sharpness"
		3:
			return "r"
		4:
			return "g"
		5:
			return "b"


func _get_input_port_type(port: int):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		1:
			return VisualShaderNode.PORT_TYPE_SCALAR
		2:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		3:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		4:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		5:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		

func _get_output_port_count() -> int:
	return 4

func _get_output_port_name(port: int):
	match port:
		0:
			return "Weights"
		1:
			return "GridID1"
		2:
			return "GridID2"
		3:
			return "GridID3"

func _get_output_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_VECTOR_3D
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		2:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D
		3:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_global_code(mode):
	var code : String = preload("res://Resources/ShaderNodes/HexagonalGrid.gdshaderinc").code
	return code

func _get_code(input_vars, output_vars, mode, type):
	var uv = "UV"
	
	if input_vars[0]:
		uv = input_vars[0]
	
	return """%s = hexagonalGrid(%s, %s, %s, %s, %s, %s); 
	""" % [
			output_vars[0], uv, input_vars[2], input_vars[1], output_vars[1], output_vars[2], output_vars[3]]
