class_name Penguins
extends Node3D

const SPAWN_Y = 25.0

@onready var rico: TalkingCharacter = $rico
@onready var kowalski: TalkingCharacter = $kowalski
@onready var private: TalkingCharacter = $private
@onready var skipper: TalkingCharacter = $skipper

@onready var bounds_top_left = $SpawnBounds/top_left
@onready var bounds_bottom_right = $SpawnBounds/bottom_right


# Called when the node enters the scene tree for the first time.
func _ready():
	reset_penguins()


func reset_penguins():
	var pengs: Array[TalkingCharacter] = [rico, kowalski, private, skipper]
	for peng in pengs:
		peng.reset_state()
		peng.transform.origin = _rand_pos()
		peng.set_rotation(_rand_rot())
		peng.linear_velocity = Vector3.ZERO
		peng.angular_velocity = Vector3.ZERO
		peng.force_update_transform()


func _rand_pos() -> Vector3:
	var minx = bounds_bottom_right.global_position.x
	var maxx = bounds_top_left.global_position.x
	var minz = bounds_bottom_right.global_position.z
	var maxz = bounds_top_left.global_position.z
	return Vector3(randf_range(minx, maxx), SPAWN_Y, randf_range(minz, maxz))


func _rand_rot() -> Vector3:
	return Vector3(0.0, randf_range(0.0, 2 * PI), 0.0)
