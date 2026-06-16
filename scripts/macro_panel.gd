extends PanelContainer

@onready var _game_world: Control = $Margin/Content/GameWorld
@onready var _tunnel_preview: TextureRect = $Margin/Content/TunnelPreview

func _ready() -> void:
	theme_type_variation = &"MacroPanel"
	custom_minimum_size = Vector2(GameConfig.macro_width(), GameConfig.panel_height())
	_game_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tunnel_preview.texture = _load_texture("res://assets/sprites/tunnel-tileset.png")

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("Failed to load texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)
