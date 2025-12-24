extends Camera3D

@export var follow_distance: float = 30
@export var follow_height: float = 30
@export var stiffness: float = 10
@export var look_ahead: float = 15

var target: Node3D = null

func _ready() -> void:
	current = true

func _physics_process(delta: float) -> void:
	if target == null:
		return

	var basis = target.global_transform.basis
	var forward = -basis.z

	var desired = target.global_transform.origin \
		- forward * follow_distance \
		+ Vector3.UP * follow_height

	var t = 1.0 - exp(-stiffness * delta)
	global_transform.origin = global_transform.origin.lerp(desired, t)

	look_at(target.global_transform.origin + forward * look_ahead, Vector3.UP)
