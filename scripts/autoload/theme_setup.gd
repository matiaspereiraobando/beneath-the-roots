extends Node
## Applies game theme + runtime pixel font (avoids requiring pre-imported .fontdata in repo).

func _ready() -> void:
	var theme: Theme = load("res://assets/theme/game_theme.tres").duplicate()
	var font := FontFile.new()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.load_dynamic_font("res://assets/fonts/pixel.ttf")
	theme.default_font = font
	theme.default_font_size = 16
	get_tree().root.theme = theme
