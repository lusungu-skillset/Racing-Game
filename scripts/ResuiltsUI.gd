extends Control

signal replay_pressed
signal menu_pressed

func _ready():
	visible = false
	$Panel/HBoxContainer/ReplayButton.pressed.connect(_on_replay_pressed)
	$Panel/HBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)

func show_results(position: int, time: float):
	$Panel/Label_Time.text = "Time: " + format_time(time)
	$Panel/Label_Position.text = "Position: " + str(position)
	visible = true

func format_time(t: float) -> String:
	var minutes = int(t / 60)
	var seconds = int(t) % 60
	var ms = int((t - int(t)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, ms]

func _on_replay_pressed():
	print("Replay button clicked!")
	emit_signal("replay_pressed")

func _on_menu_pressed():
	print("Menu button clicked!")
	emit_signal("menu_pressed")
