extends RefCounted
class_name HudTheme

# Stitch "Earthen Root" palette (from beneath_the_roots-stitch-hud/DESIGN.md)
const SURFACE_CONTAINER_LOW := Color(0.101961, 0.109804, 0.117647, 1)  # #1a1c1e
const SURFACE_CONTAINER := Color(0.117647, 0.12549, 0.133333, 1)  # #1e2022
const SURFACE_CONTAINER_HIGHEST := Color(0.2, 0.207843, 0.215686, 0.5)  # #333537 @ 50%
const SURFACE_CONTAINER_LOWEST := Color(0.047059, 0.054902, 0.062745, 1)  # #0c0e10
const ON_SURFACE := Color(0.886275, 0.886275, 0.898039, 1)  # #e2e2e5
const ON_SURFACE_VARIANT := Color(0.898039, 0.745098, 0.721569, 0.7)  # #e5beb8
const SECONDARY := Color(0.745098, 0.792157, 0.705882, 1)  # #becab4
const SECONDARY_CONTAINER := Color(0.254902, 0.298039, 0.231373, 1)  # #414c3b
const ON_SECONDARY_FIXED_VARIANT := Color(0.247059, 0.290196, 0.223529, 1)  # #3f4a39
const PRIMARY := Color(1.0, 0.705882, 0.662745, 1)  # #ffb4a9
const PRIMARY_CONTAINER := Color(1.0, 0.333333, 0.266667, 1)  # #ff5544
const TERTIARY := Color(0.901961, 0.745098, 0.678431, 1)  # #e6bead
const OUTLINE_VARIANT := Color(0.360784, 0.25098, 0.235294, 0.3)  # #5c403c
const MOSS_BORDER := Color(0.254902, 0.298039, 0.231373, 1)  # #414c3b
const ERROR := Color(1.0, 0.705882, 0.670588, 1)  # #ffb4ab
const HP_FILL_END := Color(0.290196, 0.870588, 0.501961, 1)  # #4ade80
const SATIETY_FILL_START := Color(0.917647, 0.345098, 0.047059, 1)  # #ea580c
const SATIETY_FILL_END := Color(0.984314, 0.74902, 0.141176, 1)  # #fbbf24

# Silkscreen (pixel.ttf) is an 8px-grid bitmap font — only multiples of 8 render crisply.
const PIXEL_FONT_STEP := 8
const FONT_CAPTION := 8
const FONT_STAT := 16
const OUTLINE_CAPTION := 2
const OUTLINE_STAT := 3


static func snap_pixel_font_size(requested: int) -> int:
	return clampi(
		int(round(float(requested) / float(PIXEL_FONT_STEP))) * PIXEL_FONT_STEP,
		PIXEL_FONT_STEP,
		64,
	)


static func apply_pixel_font(control: Control, size_px: int, outline_px: int = -1) -> void:
	var font_size := snap_pixel_font_size(size_px)
	control.add_theme_font_size_override("font_size", font_size)
	if outline_px < 0:
		outline_px = OUTLINE_STAT if font_size >= FONT_STAT else OUTLINE_CAPTION
	control.add_theme_constant_override("outline_size", outline_px)


static func apply_pixel_label(label: Label, size_px: int, outline_px: int = -1) -> void:
	apply_pixel_font(label, size_px, outline_px)


static func game_hud_panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = SURFACE_CONTAINER_LOW
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 4
	box.border_color = MOSS_BORDER
	box.set_corner_radius_all(4)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 2)
	return box


static func icon_well() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = SECONDARY_CONTAINER
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.border_color = ON_SECONDARY_FIXED_VARIANT
	box.set_corner_radius_all(4)
	return box


static func wave_pill() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = SURFACE_CONTAINER_HIGHEST
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = OUTLINE_VARIANT
	box.set_corner_radius_all(999)
	return box


static func ant_strip() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(SURFACE_CONTAINER.r, SURFACE_CONTAINER.g, SURFACE_CONTAINER.b, 0.6)
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = OUTLINE_VARIANT
	box.set_corner_radius_all(2)
	return box


static func carved_trough() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = SURFACE_CONTAINER_LOWEST
	box.border_width_left = 1
	box.border_width_top = 1
	box.border_width_right = 1
	box.border_width_bottom = 1
	box.border_color = Color(0, 0, 0, 0.5)
	box.set_corner_radius_all(2)
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 1
	box.shadow_offset = Vector2(1, 1)
	return box


static func toolbar_panel() -> StyleBoxFlat:
	var box := game_hud_panel()
	box.border_width_left = 0
	box.border_width_right = 0
	box.border_width_top = 0
	box.border_width_bottom = 0
	box.shadow_size = 0
	box.shadow_offset = Vector2.ZERO
	return box


static func apply_toolbar_text_button(btn: Button, accent: Color = ON_SURFACE) -> void:
	apply_pixel_font(btn, FONT_CAPTION)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", PRIMARY)
	btn.add_theme_color_override("font_pressed_color", PRIMARY)
	btn.add_theme_color_override("font_disabled_color", ON_SURFACE_VARIANT)
	btn.add_theme_stylebox_override("normal", ant_strip())
	btn.add_theme_stylebox_override("hover", wave_pill())
	btn.add_theme_stylebox_override("pressed", wave_pill())
	btn.add_theme_stylebox_override("disabled", ant_strip())


static func apply_menu_close_button(btn: Button) -> void:
	btn.custom_minimum_size = Vector2(32, 32)
	btn.text = "×"
	btn.tooltip_text = "Close"
	apply_pixel_font(btn, FONT_STAT, OUTLINE_STAT)
	btn.add_theme_color_override("font_color", ON_SURFACE)
	btn.add_theme_color_override("font_hover_color", PRIMARY)
	btn.add_theme_color_override("font_pressed_color", PRIMARY_CONTAINER)
	btn.add_theme_stylebox_override("normal", icon_well())
	btn.add_theme_stylebox_override("hover", wave_pill())
	btn.add_theme_stylebox_override("pressed", wave_pill())
	btn.add_theme_stylebox_override("focus", icon_well())


static func apply_toolbar_icon_button(btn: Button) -> void:
	apply_pixel_font(btn, FONT_CAPTION)
	btn.add_theme_stylebox_override("normal", icon_well())
	btn.add_theme_stylebox_override("hover", wave_pill())
	btn.add_theme_stylebox_override("pressed", wave_pill())
	btn.add_theme_stylebox_override("disabled", icon_well())
	btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	btn.add_theme_color_override("icon_pressed_color", PRIMARY)
	btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	btn.add_theme_color_override("icon_disabled_color", ON_SURFACE_VARIANT)


static func set_toolbar_toggle_pressed(btn: Button, is_on: bool) -> void:
	if is_on:
		btn.add_theme_stylebox_override("normal", wave_pill())
		btn.add_theme_stylebox_override("pressed", wave_pill())
		btn.add_theme_color_override("font_color", PRIMARY)
		btn.add_theme_color_override("font_pressed_color", PRIMARY)
	else:
		btn.add_theme_stylebox_override("normal", ant_strip())
		btn.add_theme_stylebox_override("pressed", wave_pill())
		btn.add_theme_color_override("font_color", ON_SURFACE)
		btn.add_theme_color_override("font_pressed_color", PRIMARY)

