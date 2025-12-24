extends Area3D

signal crossed_line(car)

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("ai_cars"):
		emit_signal("crossed_line", body)
