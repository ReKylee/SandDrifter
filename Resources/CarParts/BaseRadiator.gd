extends Resource
class_name Radiator

#considering the radiator area ,A  and length, L 
#heat flow,q=Q/A (q(m/s) , Q(m^3/s) are flows)
#Coolant side : (  Temperature of coolant - Temperature of coolant,wall) = (1/h,coolant)*(heat flow)
#Wall side: (  Temperature of coolant,wall - Temperature of air,wall) = (L/k)*(heat flow)
#Air Side: (  Temperature of air,wall - Temperature of air) = (1/h,air)*(heat flow)
#The average values of the conduction and convection can be taken as h,c=3000 W/(m2K) , k= 200-400 W/mK ( depending on the radiator material) , h,a= 100 W/(m2K) ( This gives the main contribution-> air side)
#Kr= 1/(1/hc + L/k + 1/ha)
#Then by considering the final result we have Q=Kr*A*(T,coolant - T,air)


@export var radiator_area : float
@export var radiator_length : float

var h_coolant = 3000 # W/M^2K 
var k = 400 #200-400 W/mK ( depending on the radiator material)
var h_air = 100 # W/M^2K


func radiator_thermal_conductivity():
	return 1/(1/h_coolant + radiator_length/k + 1/h_air)

func heat_flow(T_coolant, T_air ):
	return radiator_thermal_conductivity() * radiator_area * (T_coolant - T_air)
