extends Area2D


func _on_body_entered(_body):
	SignalBus.player_died.emit()

