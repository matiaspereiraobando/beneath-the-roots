extends Node
## Applies game theme + runtime pixel font (avoids requiring pre-imported .fontdata in repo).

func _ready() -> void:
	var theme: Theme = load("res://assets/theme/game_theme.tres").duplicate()
	var font := FontFile.new()
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.load_dynamic_font("res://assets/fonts/pixel.ttf")
	# Silkscreen is an 8px-grid font; use sizes 8, 16, 24, … (see HudTheme.PIXEL_FONT_STEP).
	theme.default_font = font
	theme.default_font_size = 16
	const HudThemeRes = preload("res://scripts/util/hud_theme.gd")
	theme.set_font_size("font_size", "TooltipLabel", HudThemeRes.FONT_CAPTION)
	theme.set_constant("outline_size", "TooltipLabel", HudThemeRes.OUTLINE_CAPTION)
	get_tree().root.theme = theme
