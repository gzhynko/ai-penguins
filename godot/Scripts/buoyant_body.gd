class_name BuoyantBody
extends RigidBody3D

const WATER_Y = 0.0

var float_force = 128.0
var water_drag = 0.01
var water_angular_drag = 0.01

var is_submerged = false

@onready var b_probes = $BuoyancyProbesContainer.get_children()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func reset_state():
	is_submerged = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	is_submerged = false
	for p in b_probes:
		p = p as Marker3D
		var depth = WATER_Y - p.global_position.y
		if depth > 0:
			is_submerged = true
			apply_force(Vector3.UP * float_force * gravity_scale * depth, p.global_position - global_position)


func _integrate_forces(state: PhysicsDirectBodyState3D):
	if is_submerged:
		state.linear_velocity *= 1 - water_drag
		state.angular_velocity *= 1 - water_angular_drag
