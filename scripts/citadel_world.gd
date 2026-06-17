extends Node2D

const AntType = preload("res://scripts/data/ant_types.gd").Type
const NurseryLayout = preload("res://scripts/data/nursery_layout.gd")
const NurseryAntSprites = preload("res://scripts/util/nursery_ant_sprites.gd")
const PixelArt = preload("res://scripts/util/pixel_art.gd")
const SpritePaths = preload("res://scripts/util/sprite_paths.gd")

@onready var camera: Camera2D = $Camera2D
@onready var background: Sprite2D = $Background
@onready var path_gatherer: Path2D = $Paths/PathGatherer
@onready var path_builder: Path2D = $Paths/PathBuilder
@onready var path_soldier: Path2D = $Paths/PathSoldier
@onready var queen_sprite: Sprite2D = $QueenSprite
@onready var queen_overlay: ColorRect = $QueenOverlay

const PATROL_SPEED := 42.0
const SIDE_SPRITE_SCALE := 2.0
const AMBIENT_ANTS := {
	AntType.GATHERER: 2,
	AntType.BUILDER: 1,
	AntType.SOLDIER: 1,
}

var _flash_time := 0.0
var _ants: Array[Dictionary] = []
var _max_visible_soldiers := 8
var _path_by_type: Dictionary = {}


func _ready() -> void:
	_path_by_type = {
		AntType.GATHERER: path_gatherer,
		AntType.BUILDER: path_builder,
		AntType.SOLDIER: path_soldier,
	}
	NurseryLayout.apply_path_curves(path_gatherer, path_builder, path_soldier)
	_setup_background()
	_setup_queen_sprite()
	refit_camera()
	call_deferred("refit_camera")
	get_viewport().size_changed.connect(refit_camera)
	GameState.citadel_breached.connect(_on_breach)
	GameState.ant_spawned.connect(_on_ant_spawned)
	GameState.level_loaded.connect(func(_id): _sync_ant_visuals())
	queen_overlay.visible = false
	_position_breach_overlay()
	call_deferred("_sync_ant_visuals")


func _setup_background() -> void:
	var path := SpritePaths.micro_background()
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null:
		tex = PixelArt.load_texture(path, 0, 1.0)
	if tex == null:
		push_warning("Nursery background missing: %s" % path)
		return
	background.texture = tex
	background.centered = true
	background.position = NurseryLayout.NATIVE_SIZE * 0.5
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _setup_queen_sprite() -> void:
	var path := SpritePaths.micro_queen_sprite()
	var tex: Texture2D
	if path != "":
		tex = PixelArt.load_texture(path, 0, 1.0)
	if tex == null:
		tex = NurseryAntSprites.queen_texture()
	queen_sprite.texture = tex
	queen_sprite.position = NurseryLayout.QUEEN_ANCHOR
	queen_sprite.centered = true
	queen_sprite.scale = Vector2(SIDE_SPRITE_SCALE, SIDE_SPRITE_SCALE)
	queen_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _position_breach_overlay() -> void:
	var rect := NurseryLayout.BREACH_RECT
	queen_overlay.position = rect.position
	queen_overlay.size = rect.size


func refit_camera() -> void:
	var map_size := NurseryLayout.NATIVE_SIZE
	camera.position = map_size * 0.5
	camera.enabled = true
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		return
	var zoom_x := vp_size.x / map_size.x
	var zoom_y := vp_size.y / map_size.y
	# Fit full nursery; square viewport keeps margins minimal.
	var zoom := minf(zoom_x, zoom_y) * 0.98
	camera.zoom = Vector2(zoom, zoom)


func _ant_texture(ant_type: int) -> Texture2D:
	var path := SpritePaths.micro_ant_sprite(ant_type)
	if path != "":
		var tex := PixelArt.load_texture(path, 0, 1.0)
		if tex:
			return tex
	return NurseryAntSprites.texture_for_type(ant_type)


func _on_ant_spawned(ant_type: int) -> void:
	_spawn_ant_visual(ant_type)


func _sync_ant_visuals() -> void:
	_clear_ant_visuals()
	_spawn_ambient_ants()
	for i in GameState.gatherer_count:
		_spawn_ant_visual(AntType.GATHERER)
	for i in GameState.builder_count:
		_spawn_ant_visual(AntType.BUILDER)
	var soldiers_to_show := mini(GameState.free_soldiers, _max_visible_soldiers)
	for i in soldiers_to_show:
		_spawn_ant_visual(AntType.SOLDIER)


func _clear_ant_visuals() -> void:
	for route: Path2D in _path_by_type.values():
		for child in route.get_children():
			if child is PathFollow2D:
				child.queue_free()
	_ants.clear()


func _spawn_ambient_ants() -> void:
	for ant_type: int in AMBIENT_ANTS:
		for i in AMBIENT_ANTS[ant_type]:
			_spawn_ant_visual(ant_type)


func _spawn_ant_visual(ant_type: int) -> void:
	var route: Path2D = _path_by_type.get(ant_type)
	if route == null or route.curve == null or route.curve.point_count < 2:
		return
	var tex := _ant_texture(ant_type)
	if tex == null:
		return
	var follower := PathFollow2D.new()
	follower.rotates = false
	route.add_child(follower)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	sprite.scale = Vector2(SIDE_SPRITE_SCALE, SIDE_SPRITE_SCALE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	follower.add_child(sprite)
	var length := route.curve.get_baked_length()
	var start_offset := randf() * length
	follower.progress = start_offset
	_ants.append({
		"follower": follower,
		"route": route,
		"sprite": sprite,
		"type": ant_type,
		"progress": start_offset,
		"length": length,
		"forward": randf() > 0.5,
	})


func _process(delta: float) -> void:
	_update_ants(delta)
	if _flash_time > 0.0:
		_flash_time -= delta
		var t := _flash_time / 0.5
		queen_overlay.modulate = Color(1, 0.3, 0.3, t * 0.6)
		if _flash_time <= 0.0:
			queen_overlay.visible = false


func _update_ants(delta: float) -> void:
	for ant in _ants:
		var follower: PathFollow2D = ant.follower
		var sprite: Sprite2D = ant.sprite
		var length: float = ant.length
		if length <= 0.0:
			continue
		var step := PATROL_SPEED * delta
		if ant.forward:
			ant.progress += step
			if ant.progress >= length:
				ant.progress = length
				ant.forward = false
		else:
			ant.progress -= step
			if ant.progress <= 0.0:
				ant.progress = 0.0
				ant.forward = true
		follower.progress = ant.progress
		var curve: Curve2D = ant.route.curve
		var p0 := curve.sample_baked(ant.progress)
		var p1 := curve.sample_baked(clampf(ant.progress + 2.0, 0.0, length))
		if absf(p1.x - p0.x) > 0.05:
			sprite.flip_h = (p1.x - p0.x) < 0.0


func _on_breach(_damage: int) -> void:
	_flash_time = 0.5
	queen_overlay.visible = true
