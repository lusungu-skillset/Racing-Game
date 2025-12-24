extends Camera3D

@onready var target = get_parent()

var follow_speed = 5.0
var distance = 6.0
var height = 3.0

func _physics_process(delta):
	if not target:
		return

	var target_pos = target.global_transform.origin
	var desired_pos = target_pos - target.global_transform.basis.z * distance
	desired_pos.y += height

	global_transform.origin = global_transform.origin.lerp(desired_pos, follow_speed * delta)
	look_at(target_pos, Vector3.UP)
