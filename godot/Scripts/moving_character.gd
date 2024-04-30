class_name MovingCharacter
extends BuoyantBody

var wander_area: WanderArea

var walk_speed: float = 5.0
var wander_rotation_speed: float = 0.8
var look_at_rotation_speed: float = 1.0

var change_dir_timer: float
var move_timer: float
var stand_timer: float

var is_changing_dir: bool = false
var is_walking: bool = false
var is_wandering: bool = false
var look_target: Node3D = null

var wander_target_rotation: float

@onready var movement_anims: AnimationPlayer = $"MovementAnimPlayer"


# Called when the node enters the scene tree for the first time.
func _ready():
	wander_area = get_node("../../WanderArea")
	start_wandering()
	movement_anims.play("idle")
	movement_anims.advance(randf_range(0.0, 2.0))


func start_wandering():
	is_wandering = true
	is_changing_dir = false
	look_target = null
	wander_target_rotation = rotation.y
	reset_timers()


func stop_and_look_at(node: Node3D):
	is_wandering = false
	look_target = node
	_play_idle()
	reset_timers()


func reset_state():
	super.reset_state()
	
	_play_idle()
	start_wandering()


func reset_timers():
	_reset_change_dir_timer()
	_reset_move_timer()
	_reset_stand_timer()


func _reset_change_dir_timer():
	change_dir_timer = randf_range(1.0, 3.0)


func _reset_move_timer():
	move_timer = randf_range(1.0, 5.0)


func _reset_stand_timer():
	stand_timer = randf_range(4.0, 14.0)


func _play_idle():
	if movement_anims.current_animation == "walk":
		movement_anims.seek(0, true)
	movement_anims.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_submerged:
		is_wandering = false
		is_changing_dir = false
		_play_idle()
	else:
		if is_wandering:
			_wander(delta)
		elif look_target:
			_process_look_at(delta)


func _wander(delta: float):
	if is_walking and not wander_area.contains(global_position):
		is_changing_dir = true
		var target_rot = transform.looking_at(wander_area.get_center(), Vector3.UP).basis.get_euler()
		wander_target_rotation = target_rot.y
	
	if is_walking and not is_changing_dir:
		change_dir_timer -= delta
	
	if not is_changing_dir and change_dir_timer <= 0:
		is_changing_dir = true
		_reset_change_dir_timer()
		wander_target_rotation = randf_range(0.0, 2 * PI)
	
	if is_changing_dir:
		if rotation.y != wander_target_rotation:
			rotation.y = lerp_angle(rotation.y, wander_target_rotation, wander_rotation_speed * delta)
		else:
			is_changing_dir = false
			wander_target_rotation = rotation.y

	if not is_walking and stand_timer <= 0:
		is_walking = true
		_reset_stand_timer()
	
	if is_walking and move_timer <= 0:
		is_walking = false
		is_changing_dir = false
		wander_target_rotation = rotation.y
		_reset_move_timer()
		_reset_change_dir_timer()
	
	if is_walking:
		movement_anims.play("walk")
		
		var move_dir = -transform.basis.z * delta * walk_speed
		move_and_push(move_dir, 0)
		
		move_timer -= delta
	else:
		_play_idle()
		stand_timer -= delta
	
	_fix_falls()


func _fix_falls():
	if abs(rotation.x) >= deg_to_rad(80) or abs(rotation.z) >= deg_to_rad(80):
		if not _is_stationary():
			return
		rotation.x = 0.0
		rotation.z = 0.0
		angular_velocity = Vector3.ZERO
		translate(Vector3(0.0, 0.5, 0.0))


func _is_stationary() -> bool:
	return abs(angular_velocity.length()) <= 0.01 and abs(linear_velocity.length()) <= 0.01


func _process_look_at(delta: float):
	var target_rot = transform.looking_at(look_target.global_position, Vector3.UP).basis.get_euler()
	rotation.y = lerp_angle(rotation.y, target_rot.y, look_at_rotation_speed * delta)


func move_and_push(move_vec: Vector3, recurse_depth: int):
	var col = move_and_collide(move_vec)
	if col and recurse_depth <= 2:
		var body = col.get_collider()
		if body is StaticBody3D:
			return
		
		if body is MovingCharacter:
			body.move_and_push(col.get_remainder(), recurse_depth + 1)
		else:
			body.move_and_collide(col.get_remainder())
		body.force_update_transform()

		move_and_collide(col.get_remainder())
