extends Control

var index: int = 0

@onready var track_label: Label = $CenterContainer/VBoxContainer/TrackLabel

func _ready() -> void:
	index = GameState.selected_track_index
	_update_label()

func _update_label() -> void:
	track_label.text = GameState.track_names[index]

func _on_previous_button_pressed() -> void:
	index = (index - 1 + GameState.track_scenes.size()) % GameState.track_scenes.size()
	_update_label()

func _on_next_button_pressed() -> void:
	index = (index + 1) % GameState.track_scenes.size()
	_update_label()

func _on_confirm_button_pressed() -> void:
	GameState.selected_track_index = index
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
