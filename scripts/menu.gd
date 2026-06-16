extends Control

func _ready() -> void:
	$Center/VBox/Level1Button.pressed.connect(_start_level.bind("level1_breach"))
	$Center/VBox/Level2Button.pressed.connect(_start_level.bind("level2_fork"))
	$Center/VBox/Level3Button.pressed.connect(_start_level.bind("level3_depth"))
	$Center/VBox/TestButton.pressed.connect(_start_level.bind("level0_test"))

func _start_level(level_id: String) -> void:
	GameState.reset_for_level(level_id)
	get_tree().change_scene_to_file("res://scenes/game.tscn")
