extends Control

var index: int = 0

@onready var car_image: TextureRect = $CenterContainer2/CarContainer/CarImage
@onready var car_name: Label = $CenterContainer2/CarContainer/CarName
@onready var speed_label: Label = $CenterContainer2/CarContainer/StatsContainer/SpeedLabel
@onready var acceleration_label: Label = $CenterContainer2/CarContainer/StatsContainer/AccelerationLabel
@onready var handling_label: Label = $CenterContainer2/CarContainer/StatsContainer/HandlingLabel

func _ready() -> void:
	_update_car_display()

func _update_car_display() -> void:
	var car = GameState.cars[index]

	car_image.texture = car["image"]
	car_name.text = car["name"]
	speed_label.text = "Speed: " + str(car["speed"])
	acceleration_label.text = "Acceleration: " + str(car["acceleration"])
	handling_label.text = "Handling: " + str(car["handling"])

func _on_previous_button_pressed():
	index = (index - 1 + GameState.cars.size()) % GameState.cars.size()
	_update_car_display()

func _on_next_button_pressed():
	index = (index + 1) % GameState.cars.size()
	_update_car_display()

func _on_confirm_button_pressed():
	GameState.selected_car_index = index
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
