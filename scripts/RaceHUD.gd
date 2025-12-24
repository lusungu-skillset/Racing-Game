extends CanvasLayer

func _ready():
	$Label_Countdown.visible = false
	$Label_Lap.visible = true
	$Label_Position.visible = true

func update_lap(current_lap: int, total_laps: int):
	$Label_Lap.text = "Lap %d / %d" % [current_lap, total_laps]

func update_position(position: int):
	var suffix := "th"
	match position:
		1: suffix = "st"
		2: suffix = "nd"
		3: suffix = "rd"
	$Label_Position.text = "Position: %d%s" % [position, suffix]

func play_countdown(callback: Callable):
	$Label_Countdown.visible = true
	await countdown(callback)

func countdown(callback: Callable) -> void:
	var numbers := ["3", "2", "1", "GO!"]

	for n in numbers:
		$Label_Countdown.text = n
		await get_tree().create_timer(1.0).timeout

	$Label_Countdown.visible = false
	callback.call()
