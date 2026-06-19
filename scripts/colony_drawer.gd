extends PanelContainer

const HudThemeRes = preload("res://scripts/util/hud_theme.gd")


func _ready() -> void:
	theme_type_variation = &"GameHud"
	var title: Label = $Margin/VBox/Title
	HudThemeRes.apply_pixel_font(title, HudThemeRes.FONT_STAT)
