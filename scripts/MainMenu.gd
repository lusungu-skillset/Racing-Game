extends Control

func _on_start_button_pressed() -> void:
	var track_scene: PackedScene = GameState.get_selected_track_scene()
	get_tree().change_scene_to_packed(track_scene)

func _on_select_car_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/SelectCarMenu.tscn")

func _on_select_track_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/SelectTrackMenu.tscn")
