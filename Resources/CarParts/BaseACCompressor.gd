extends Resource
class_name ACCompressor



#Volume Flow Rate = (Q x 60) / (T x 14.7)

@export_range(400, 1000) var flow_rate : float = 502 # In Cubic feet per minute
@export var T : float = 30 #Time in minutes
@export var pressure : float #Pressure in psi

func volume_flow_rate():
	return (flow_rate * 60) / (T * 14.7)

func power():
	return pressure * volume_flow_rate() / T
