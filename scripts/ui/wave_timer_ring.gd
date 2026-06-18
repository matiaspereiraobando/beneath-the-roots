extends Control
class_name WaveTimerRing

const HudThemeRes = preload("res://scripts/util/hud_theme.gd")

@export var ring_color: Color = HudThemeRes.PRIMARY_CONTAINER
@export var track_color: Color = HudThemeRes.SURFACE_CONTAINER_HIGHEST

var seconds_remaining: float = 0.0
var interval: float = 40.0
var invasion_glow: bool = false

@onready var _label: Label = $Label


func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	if _label == null:
		_label = Label.new()
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_label)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	HudThemeRes.apply_pixel_label(_label, HudThemeRes.FONT_STAT)
	_label.add_theme_color_override("font_color", HudThemeRes.ON_SURFACE)


func set_timer(remaining: float, total: float) -> void:
	seconds_remaining = maxf(0.0, remaining)
	interval = maxf(0.001, total)
	if _label:
		if GameState.phase == GameState.Phase.WON:
			_label.text = "WIN"
		elif GameState.phase == GameState.Phase.LOST:
			_label.text = "X"
		else:
			_label.text = str(int(ceilf(seconds_remaining)))
	queue_redraw()


func set_invasion_active(active: bool) -> void:
	invasion_glow = active
	set_process(active)
	if not active:
		modulate = Color.WHITE
	queue_redraw()


func _process(_delta: float) -> void:
	if invasion_glow:
		var pulse := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.006)
		modulate = Color(pulse, pulse, pulse, 1.0)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.45
	var track_w := 3.0
	draw_arc(center, radius, 0.0, TAU, 48, track_color, track_w, true)
	var ratio := clampf(seconds_remaining / interval, 0.0, 1.0)
	if ratio > 0.001:
		var start := -PI * 0.5
		var end := start + TAU * ratio
		var col := ring_color
		if invasion_glow:
			col = col.lerp(Color.WHITE, 0.15)
		draw_arc(center, radius, start, end, 48, col, track_w, true)
