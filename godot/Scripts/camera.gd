class_name Camera
extends Camera3D

const RESET_POS = Vector3(0.0, FOLLOW_Y, 120.0)
const RESET_ROT_DEG = Vector3(-20, 0, 0)

const FOLLOW_Y = 50.0
const TARGET_DISTANCE = 30.0
const MIN_DISTANCE = 5.0

var following: Node3D


func _ready():
	reset_position()


func reset_position():
	follow_node(null)
	position = RESET_POS
	rotation_degrees = RESET_ROT_DEG


func follow_node(node: Node3D):
	following = node


func _physics_process(delta):
	if following == null:
		return
	
	face_target(Vector3(following.position.x, following.position.y + 5.0, following.position.z), 0.1)
	
	var dist_to_target = Vector2(position.x, position.z).distance_to(Vector2(following.position.x, following.position.z))
	var target_pos = Vector3(following.position.x, FOLLOW_Y, following.position.z)
	if dist_to_target > TARGET_DISTANCE:
		var lerp_speed = min(30.0, dist_to_target - TARGET_DISTANCE)
		position = position.move_toward(target_pos, lerp_speed * delta)
		position.y = FOLLOW_Y
	elif dist_to_target < TARGET_DISTANCE and dist_to_target > MIN_DISTANCE:
		var lerp_speed = 5.0
		position = position.move_toward(target_pos, -1 * lerp_speed * delta)
		position.y = FOLLOW_Y


func face_target(pos, weight):
	var target_rot = transform.looking_at(pos, Vector3.UP).basis.get_rotation_quaternion()
	rotation = quaternion.slerp(target_rot, weight).get_euler()
