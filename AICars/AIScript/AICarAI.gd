extends CharacterBody3D

const GSAISteeringAgent      := preload("res://addons/com.gdquest.godot-steering-ai-framework/GSAISteeringAgent.gd")
const GSAITargetAcceleration := preload("res://addons/com.gdquest.godot-steering-ai-framework/GSAITargetAcceleration.gd")

@export var path_node: Path3D
@export var max_speed: float = 10
@export var max_accel: float = 30
@export var corner_slowdown: float = 0.6
@export var waypoint_distance: float = 3.0

@export var separation_radius: float = 5.0
@export var separation_strength: float = 8.0

@export_enum("EASY", "MEDIUM", "HARD")
var difficulty: String = "MEDIUM"

var agent: GSAISteeringAgent
var curve_points: PackedVector3Array
var current_index: int = 0

var accel: GSAITargetAcceleration = GSAITargetAcceleration.new()
var gravity_amount: float = -30.0   # keeps car glued to track

func _ready() -> void:
	add_to_group("ai_cars")

	if path_node == null or path_node.curve == null:
		push_error("AICarAI ERROR: path_node or curve missing.")
		set_physics_process(false)
		return

	curve_points = path_node.curve.get_baked_points()
	if curve_points.is_empty():
		push_error("AICarAI ERROR: Path has no baked points.")
		set_physics_process(false)
		return

	match difficulty:
		"EASY":   max_speed *= 0.9
		"MEDIUM": max_speed *= 1.0
		"HARD":   max_speed *= 1.05

	agent = GSAISteeringAgent.new()
	agent.linear_speed_max = max_speed
	agent.linear_acceleration_max = max_accel
	agent.linear_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	var pos: Vector3 = global_transform.origin


	var target: Vector3 = curve_points[current_index]
	var to_target: Vector3 = target - pos

	if to_target.length() < waypoint_distance:
		current_index = (current_index + 1) % curve_points.size()
		target = curve_points[current_index]
		to_target = target - pos

	var dir: Vector3 = to_target.normalized()

	var look_ahead_index: int = (current_index + 5) % curve_points.size()
	var look_ahead: Vector3 = curve_points[look_ahead_index]
	var ahead_dir: Vector3 = (look_ahead - target).normalized()

	var angle: float = dir.angle_to(ahead_dir)
	var slow_factor: float = lerp(1.0, corner_slowdown, clamp(angle * 3.0, 0.0, 1.0))
	var target_speed: float = max_speed * slow_factor

	var separation_vec: Vector3 = Vector3.ZERO
	for n in get_tree().get_nodes_in_group("ai_cars"):
		if n == self:
			continue
		var other: Vector3 = n.global_position
		var diff: Vector3 = pos - other
		var dist: float = diff.length()
		if dist < separation_radius and dist > 0.1:
			var weight: float = (separation_radius - dist) / separation_radius
			separation_vec += diff.normalized() * separation_strength * weight

	if separation_vec.length() > 0.01:
		dir = (dir + separation_vec.normalized() * 0.3).normalized()


	var desired: Vector3 = dir * target_speed

	agent.linear_velocity = agent.linear_velocity.move_toward(
		desired,
		max_accel * delta
	)


	agent.linear_velocity.y += gravity_amount * delta

	velocity = agent.linear_velocity
	move_and_slide()


	if velocity.length() > 0.1:
		var flat: Vector3 = Vector3(velocity.x, 0, velocity.z)
		if flat.length() > 0.01:
			var target_rot: Basis = transform.looking_at(pos + flat, Vector3.UP).basis
			basis = basis.slerp(target_rot, 0.08) 
