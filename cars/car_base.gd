extends CharacterBody3D

@export var gravity: float = -20.0
@export var wheel_base: float = 0.6

@export var steering_limit: float = 5.0
@export var max_steering_angle: float = 3.0
@export var steering_lerp: float = 6.0
@export var speed_steering_factor: float = 0.015

@export var grip: float = 10.0
@export var drift_loss: float = 0.6

@export var engine_power: float = 100
@export var engine_accel: float = 100
@export var max_speed: float = 100
@export var gear_shift_speed: float = 18.0

@export var brake_strength: float = 8.0
@export var abs_strength: float = 3.0


@export var drag: float = 1.5
@export var rolling_friction: float = 1.0


var lin_vel: Vector3 = Vector3.ZERO
var acceleration: Vector3 = Vector3.ZERO
var steer_angle: float = 0.0
var steer_target: float = 0.0
var gear: int = 1



func _physics_process(delta: float) -> void:
	get_input(delta)
	apply_engine(delta)
	apply_friction(delta)
	calculate_steering(delta)
	apply_traction(delta)

	acceleration.y = gravity

	lin_vel += acceleration * delta
	velocity = lin_vel
	move_and_slide()
	lin_vel = velocity



func get_input(delta: float) -> void:
	var turn: float = Input.get_action_strength("steer_left") \
					- Input.get_action_strength("steer_right")

	var speed: float = lin_vel.length()
	var speed_factor: float = max(0.15, 1.0 - (speed * speed_steering_factor))

	steer_target = turn * deg_to_rad(max_steering_angle) * speed_factor
	steer_angle = lerp(steer_angle, steer_target, delta * steering_lerp)

	acceleration = Vector3.ZERO

	if Input.is_action_pressed("accelerate"):
		acceleration -= global_transform.basis.z * engine_accel

	if Input.is_action_pressed("brake"):
		var power: float = brake_strength
		if speed < 1.0:
			power *= abs_strength
		acceleration += global_transform.basis.z * power




func apply_engine(delta: float) -> void:
	var speed: float = lin_vel.length()

	gear = clamp(int(speed / gear_shift_speed) + 1, 1, 5)
	var gear_mult: float = 0.9 - (gear * 0.12)

	if Input.is_action_pressed("accelerate") and speed < max_speed:
		var torque: float = engine_power * gear_mult
		acceleration -= global_transform.basis.z * torque




func apply_friction(delta: float) -> void:
	if lin_vel.length() < 0.3 and acceleration.length() == 0.0:
		lin_vel.x = 0.0
		lin_vel.z = 0.0

	var drag_force: Vector3 = lin_vel * lin_vel.length() * drag * delta
	var roll_force: Vector3 = lin_vel * rolling_friction * delta

	acceleration -= drag_force + roll_force


func calculate_steering(delta: float) -> void:
	var t := global_transform

	var rear: Vector3 = t.origin + t.basis.z * wheel_base * 0.5
	var front: Vector3 = t.origin - t.basis.z * wheel_base * 0.5

	rear += lin_vel * delta
	front += lin_vel.rotated(t.basis.y, steer_angle) * delta

	var new_dir: Vector3 = rear.direction_to(front)

	if lin_vel.length() > 0.01:
		lin_vel = new_dir * lin_vel.length()

	look_at(t.origin + new_dir, Vector3.UP)

func apply_traction(delta: float) -> void:
	var local: Vector3 = global_transform.basis.inverse() * lin_vel
	local.x *= pow(drift_loss, delta * grip)
	lin_vel = global_transform.basis * local
