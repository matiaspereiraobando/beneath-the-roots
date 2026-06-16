extends PanelContainer

@onready var _satiety_label: Label = $Margin/VBox/SatietyLabel
@onready var _queen_sprite: TextureRect = $Margin/VBox/QueenCenter/QueenSprite

func _ready() -> void:
	theme_type_variation = &"MicroPanel"
	custom_minimum_size = Vector2(GameConfig.micro_width(), GameConfig.panel_height())
	_queen_sprite.texture = _load_texture("res://assets/sprites/queen.png")
	GameState.queen_satiety_changed.connect(_on_satiety_changed)
	_on_satiety_changed(GameState.queen_satiety)

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("Failed to load texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func _on_satiety_changed(value: float) -> void:
	_satiety_label.text = "Satiety: %d%%" % int(value)
