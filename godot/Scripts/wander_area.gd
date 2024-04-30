class_name WanderArea
extends Area3D

@onready var shape: CollisionShape3D = $CollisionShape3D


func _shape_pos_vec3() -> Vector3:
	return Vector3(shape.global_position.x, 0.0, shape.global_position.z)


func _shape_pos_vec2() -> Vector2:
	return Vector2(shape.global_position.x, shape.global_position.z)


func contains(point: Vector3) -> bool:
	var box_shape = shape.shape as BoxShape3D
	var size = box_shape.size
	
	var rect2_pos = _shape_pos_vec2() - Vector2(size.x, size.z) / 2.0
	var rect2 = Rect2(rect2_pos.x, rect2_pos.y, size.x, size.z)
	
	return rect2.has_point(Vector2(point.x, point.z))


func get_center() -> Vector3:
	# the box is centered at the pos of the collision shape
	return _shape_pos_vec3()
