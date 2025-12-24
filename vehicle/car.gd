extends CharacterBody3D

# ---------- INPUT SETUP ----------
func _ready():
	add_input("Gas", [KEY_W, KEY_UP])
	add_input("Brake", [KEY_S, KEY_DOWN])
	add_input("Left", [KEY_A, KEY_LEFT])
	add_input("Right", [KEY_D, KEY_RIGHT])

func add_input(action_name: String, keys: Array):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var ev = InputEventKey.new()
		ev.keycode = key
		InputMap.action_add_event(action_name, ev)

# ---------- CAR SETTINGS ----------
@export var acceleration := 35.0
@export var max_speed := 45.0
@export var reverse_speed := 20.0
@export var turn_speed := 2.8
@export var friction := 12.0
@export var gravity := 30.0
@export var turn_amount := 0.35

var speed := 0.0    
var steering := 0.0

# WHEEL NODES
@onready var wheel_fl = $wheel_front_left
@onready var wheel_fr = $wheel_front_right
@onready var wheel_bl = $wheel_back_left
@onready var wheel_br = $wheel_back_right

# CAMERA
@onready var CamArm = $CamArm

# ---------- PHYSICS ----------
func _physics_process(delta: float) -> void:

	# throttle (forward/back)
	var dir := Input.get_action_strength("Gas") - Input.get_action_strength("Brake")

	# steering input
	var steering_dir := Input.get_action_strength("Left") - Input.get_action_strength("Right")

	# ---------- SPEED CONTROL ----------
	if dir != 0:
		speed += dir * acceleration * delta
	else:
		speed = lerp(speed, 0.0, friction * delta)

	# clamp forward/back speed
	if speed > 0:
		speed = clamp(speed, 0, max_speed)
	else:
		speed = clamp(speed, -reverse_speed, 0)

	# ---------- TURNING ----------
	if abs(speed) > 0.1:
		steering = lerp(steering, steering_dir * turn_amount, 8.0 * delta)
		rotation.y += steering * turn_speed * delta * sign(speed)

	# ---------- BUILD VELOCITY ----------
	var forward := -transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

	# ---------- WHEEL ANIMATION ----------
	_update_wheels(delta)


# ---------- WHEEL ANIMATIONS ----------
func _update_wheels(delta: float):
	# Spin wheels (based on car speed)
	var spin_speed := speed * 0.3

	wheel_fl.rotate_x(spin_speed * delta)
	wheel_fr.rotate_x(spin_speed * delta)
	wheel_bl.rotate_x(spin_speed * delta)
	wheel_br.rotate_x(spin_speed * delta)

	# Front wheels turn visually
	wheel_fl.rotation.y = steering * 0.8
	wheel_fr.rotation.y = steering * 0.8
