extends "res://cars/car_base.gd"

signal change_camera

# Camera positions under the car (PositionClose, PositionFar, etc.)
@onready var camera_positions = $"CameraPositions".get_children()
var current_camera_idx: int = 0

# SUV tuning
@export var suv_steering_angle: float = 2.0     # smoother turning
@export var suv_accel: float = 80           # stronger acceleration
@export var suv_brake: float = 7.0             # SUV brake feel


func _ready() -> void:
	# Send the first camera socket to ChaseCamera
	if camera_positions.size() > 0:
		emit_signal("change_camera", camera_positions[current_camera_idx])


func _input(event: InputEvent) -> void:
	# Switch camera views
	if event.is_action_pressed("change_camera") and camera_positions.size() > 0:
		current_camera_idx = (current_camera_idx + 1) % camera_positions.size()
		emit_signal("change_camera", camera_positions[current_camera_idx])


# -----------------------------------------------------
#   INPUT OVERRIDE (SUV driving feel)
# -----------------------------------------------------
func get_input(delta: float) -> void:
	# ------------------------
	# STEERING INPUT
	# ------------------------
	var turn: float = Input.get_action_strength("steer_left") \
					- Input.get_action_strength("steer_right")

	var speed: float = lin_vel.length()
	var speed_factor: float = max(0.2, 1.0 - (speed * speed_steering_factor))

	steer_target = turn * deg_to_rad(suv_steering_angle) * speed_factor
	steer_angle = lerp(steer_angle, steer_target, delta * steering_lerp)

	# ------------------------
	# ACCELERATION / BRAKES
	# ------------------------
	acceleration = Vector3.ZERO

	if Input.is_action_pressed("accelerate"):
		acceleration -= global_transform.basis.z * suv_accel

	if Input.is_action_pressed("brake"):
		var power: float = suv_brake
		if speed < 1.0:
			power *= abs_strength
		acceleration += global_transform.basis.z * power
