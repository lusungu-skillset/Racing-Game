extends Node

# -------------------------------------------------
#  PLAYER CAR OPTIONS
# -------------------------------------------------
var car_scenes: Array[PackedScene] = [
	preload("res://scenes/truck.tscn"),
	preload("res://scenes/suv.tscn"),
	preload("res://scenes/suv_luxury.tscn"),
	preload("res://scenes/police.tscn"),
]

var ai_car_scenes: Array[PackedScene] = [
	preload("res://AICars/AICar1.tscn"),
	preload("res://AICars/AICar2.tscn"),
	preload("res://AICars/AICar3.tscn"),
]

func get_ai_car_scene(index: int = 0) -> PackedScene:
	if index >= 0 and index < ai_car_scenes.size():
		return ai_car_scenes[index]

	return ai_car_scenes[0]


var track_scenes: Array[PackedScene] = [
	preload("res://scenes/RoadNetwork.tscn"),
	preload("res://scenes/RoadNetwork2.tscn"),
]

var track_names: Array[String] = [
	"Industrial District",
	"Desert Track"
]

var cars = [
	{
		"name": "Truck",
		"image": preload("res://cars/truck.png"),
		"speed": 100,
		"acceleration": 85,
		"handling": 60,
	},
	{
		"name": "SUV",
		"image": preload("res://cars/suv.png"),
		"speed": 200,
		"acceleration": 80,
		"handling": 60,
	},
		{
		"name": "SUV_Luxury",
		"image": preload("res://cars/suv-luxury.png"),
		"speed": 200,
		"acceleration": 80,
		"handling": 60,
	},
		{
		"name": "police",
		"image": preload("res://cars/police.png"),
		"speed": 200,
		"acceleration": 80,
		"handling": 60,
	},
]

var selected_car_index: int = 0
var selected_track_index: int = 0


func get_selected_car_scene() -> PackedScene:
	if selected_car_index < car_scenes.size():
		return car_scenes[selected_car_index]

	push_error("ERROR: Invalid selected_car_index: %s" % selected_car_index)
	return null


func get_selected_track_scene() -> PackedScene:
	if selected_track_index < track_scenes.size():
		return track_scenes[selected_track_index]

	push_error("ERROR: Invalid selected_track_index: %s" % selected_track_index)
	return null
