extends Control

const SpritePaths = preload("res://scripts/util/sprite_paths.gd")

var _bg_tex: Texture2D


func _ready() -> void:
	clip_contents = true
	_bg_tex = _load_bg_texture()
	if _bg_tex:
		queue_redraw()
	else:
		push_error("Colony drawer background failed to load: %s" % SpritePaths.colony_drawer_bg())


func _load_bg_texture() -> Texture2D:
	var path := SpritePaths.colony_drawer_bg()
	var tex := load(path) as Texture2D
	if tex != null:
		return tex
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null


func _draw() -> void:
	if _bg_tex:
		draw_texture(_bg_tex, Vector2.ZERO)
