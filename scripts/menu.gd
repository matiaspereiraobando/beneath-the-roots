extends Control

func _ready() -> void:
	$Center/VBox/Level1Button.pressed.connect(_start_level.bind("first_breach"))

func _start_level(level_id: String) -> void:
	GameState.reset_for_level(level_id)
	get_tree().change_scene_to_file("res://scenes/game.tscn")
