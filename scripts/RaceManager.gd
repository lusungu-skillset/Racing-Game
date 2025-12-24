extends Node3D


# ----------------------------------------------------
@onready var player_spawn: Marker3D = $"../PlayerSpawn"
@onready var camera_node: Camera3D = $"../ChaseCameraRoot/ChaseCamera"

# SINGLE shared AI path
@onready var ai_path: Path3D = $"../Path3D_L1"

@onready var lap_trigger: Area3D = $"../LapTrigger"

# ----------------------------------------------------
# RACE SETTINGS
# ----------------------------------------------------
@export var total_laps: int = 3
@export var number_of_ai: int = 3

# Lateral offsets for AI
var ai_lane_offsets: Array[float] = [-4.0, 0.0, 4.0]

# Race state
var player_lap: int = 0
var race_started: bool = false
var race_finished: bool = false
var race_time: float = 0.0
var countdown_done: bool = false

# Cars
var ai_laps: Dictionary = {}
var ai_cars: Array = []
var player_car: Node3D

var hud
signal race_over(final_position, final_time)


# ----------------------------------------------------
# READY
# ----------------------------------------------------
func _ready():
	print("\n--- RaceManager Starting ---")

	_spawn_player_car()
	_spawn_ai_cars()
	_connect_camera_to_player()

	hud = preload("res://scenes/RaceHUD.tscn").instantiate()
	add_child(hud)

	hud.play_countdown(Callable(self, "_start_race_after_countdown"))

	lap_trigger.body_entered.connect(_on_body_crossed_line)

	print("--- RaceManager Setup Complete ---\n")


# ----------------------------------------------------
# START RACE AFTER COUNTDOWN
# ----------------------------------------------------
func _start_race_after_countdown():
	countdown_done = true
	race_started = true
	print(">>> RACE STARTED!")


# ----------------------------------------------------
# PROCESS
# ----------------------------------------------------
func _process(delta: float) -> void:
	if countdown_done and race_started and not race_finished:
		race_time += delta

	hud.update_lap(player_lap, total_laps)
	hud.update_position(get_player_position())


# ----------------------------------------------------
# PLAYER SPAWN
# ----------------------------------------------------
func _spawn_player_car():
	var car_scene: PackedScene = GameState.get_selected_car_scene()
	player_car = car_scene.instantiate()
	player_car.add_to_group("player")
	add_child(player_car)
	player_car.global_transform = player_spawn.global_transform


# ----------------------------------------------------
# AI SPAWN
# ----------------------------------------------------
func _spawn_ai_cars():
	ai_cars.clear()

	var ai_scenes = GameState.ai_car_scenes
	if ai_scenes.is_empty():
		push_error("No AI car scenes found!")
		return

	var spawn_count: int = min(number_of_ai, ai_scenes.size())

	for i in range(spawn_count):
		var ai = ai_scenes[i].instantiate()
		ai.add_to_group("ai_cars")

		# Assign same path to all
		if "path_node" in ai:
			ai.path_node = ai_path

		# Different speeds
		if "max_speed" in ai and "max_accel" in ai:
			match i:
				1:
					ai.max_speed = 20
					ai.max_accel = 80
				2:
					ai.max_speed = 40
					ai.max_accel = 100
				3:
					ai.max_speed = 60
					ai.max_accel = 120
				

		add_child(ai)

		# Spawn behind player
		var t: Transform3D = player_spawn.global_transform
		t.origin += t.basis.z * float(-(i + 1) * 20.0)

		# FIXED TYPE — works now
		var lane_offset: float = ai_lane_offsets[i % ai_lane_offsets.size()]
		t.origin += t.basis.x * lane_offset

		ai.global_transform = t
		ai_cars.append(ai)
		ai_laps[ai] = 0

		print("AI", i, "spawned:", t.origin, "speed:", ai.max_speed)


# ----------------------------------------------------
# LAP TRIGGER
# ----------------------------------------------------
func _on_body_crossed_line(body: Node) -> void:
	if race_finished or not countdown_done:
		return

	if body == player_car:
		_process_player_lap()
	elif body in ai_laps:
		ai_laps[body] += 1


func _process_player_lap():
	player_lap += 1
	if player_lap >= total_laps:
		_finish_race()


# ----------------------------------------------------
# POSITION SYSTEM
# ----------------------------------------------------
func get_player_position() -> int:
	var ahead := 0
	var finish_pos = lap_trigger.global_transform.origin

	for ai in ai_cars:
		var ai_l = ai_laps.get(ai, 0)

		if ai_l > player_lap:
			ahead += 1
		elif ai_l == player_lap:
			var ai_dist = ai.global_transform.origin.distance_to(finish_pos)
			var p_dist = player_car.global_transform.origin.distance_to(finish_pos)
			if ai_dist < p_dist:
				ahead += 1

	return ahead + 1


# ----------------------------------------------------
# FINISH RACE
# ----------------------------------------------------
func _finish_race():
	if race_finished:
		return

	race_finished = true
	race_started = false
	hud.visible = false

	var position = get_player_position()
	var time = race_time

	var results_ui = preload("res://scripts/ResultsUI.tscn").instantiate()
	add_child(results_ui)

	results_ui.show_results(position, time)

	results_ui.replay_pressed.connect(_on_replay_pressed)
	results_ui.menu_pressed.connect(_on_menu_pressed)

	for ai in ai_cars:
		if "max_speed" in ai: ai.max_speed = 0

	if "max_speed" in player_car:
		player_car.max_speed = 0


# ----------------------------------------------------
# RESULT BUTTONS
# ----------------------------------------------------
func _on_replay_pressed():
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# ----------------------------------------------------
# CAMERA FOLLOW
# ----------------------------------------------------
func _connect_camera_to_player():
	if camera_node and player_car:
		camera_node.target = player_car
