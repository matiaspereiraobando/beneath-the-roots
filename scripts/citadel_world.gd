extends Node2D

const AntType = preload("res://scripts/data/ant_types.gd").Type
const CitadelTile = preload("res://scripts/util/placeholder_tilesets.gd").CitadelTile
const PixelArt = preload("res://scripts/util/pixel_art.gd")
const SpritePaths = preload("res://scripts/util/sprite_paths.gd")

@onready var camera: Camera2D = $Camera2D
@onready var floor_map: TileMapLayer = $FloorMap
@onready var ants_root: Node2D = $Ants
@onready var queen_sprite: Sprite2D = $QueenSprite
@onready var queen_overlay: ColorRect = $QueenOverlay

# Compact 32px grid — fits the micro viewport at readable scale.
const GRID_W := 9
const GRID_H := 12

const ROOM_NURSERY := Rect2i(1, 2, 3, 3)
const ROOM_ARMORY := Rect2i(5, 2, 3, 3)
const ROOM_CORRIDOR := Rect2i(2, 5, 5, 1)
const ROOM_QUEEN := Rect2i(2, 7, 5, 4)

var _flash_time := 0.0
var _citadel_tileset
var _ant_sprites: Dictionary = {}
var _ants: Array[Dictionary] = []
var _max_visible_soldiers := 8
var _tile_px: int = GameTuning.MICRO_TILE_SIZE


func _ready() -> void:
	_tile_px = GameTuning.MICRO_TILE_SIZE
	_citadel_tileset = load("res://scripts/util/citadel_tileset.gd").new()
	floor_map.tile_set = _citadel_tileset.tile_set
	_load_ant_textures()
	_paint_citadel()
	_setup_queen_sprite()
	_fit_camera()
	call_deferred("_fit_camera")
	GameState.citadel_breached.connect(_on_breach)
	GameState.ant_spawned.connect(_on_ant_spawned)
	GameState.level_loaded.connect(func(_id): _sync_ant_visuals())
	queen_overlay.visible = false


func _fit_camera() -> void:
	var map_size := Vector2(GRID_W * _tile_px, GRID_H * _tile_px)
	camera.position = map_size * 0.5
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var zoom_x := vp_size.x / map_size.x
	var zoom_y := vp_size.y / map_size.y
	var zoom := minf(zoom_x, zoom_y) * 0.96
	camera.zoom = Vector2(zoom, zoom)


func _load_ant_textures() -> void:
	_ant_sprites[AntType.GATHERER] = _load_ant_sprite("gatherer", SpritePaths.ant_sprite("gatherer"))
	_ant_sprites[AntType.BUILDER] = _load_ant_sprite("builder", SpritePaths.ant_sprite("builder"))
	_ant_sprites[AntType.SOLDIER] = _load_ant_sprite("soldier", SpritePaths.ant_sprite("soldier_micro"))


func _load_ant_sprite(base_name: String, static_path: String) -> Dictionary:
	# Legacy 16px walk sheets upscale poorly; only use native v2 walk strips.
	var walk_path := SpritePaths.ant_walk(base_name)
	if walk_path.contains("/v2/") and ResourceLoader.exists(walk_path):
		var sheet := PixelArt.load_texture(walk_path, 0, _sprite_brighten_for_path(walk_path))
		if sheet:
			var frame_w := sheet.get_height()
			if frame_w <= 0:
				frame_w = GameTuning.MICRO_SPRITE_NATIVE_SIZE
			return {
				"texture": sheet,
				"frame_w": frame_w,
				"frame_count": maxi(1, sheet.get_width() / frame_w),
				"animated": true,
				"scale": 1.0,
			}
	var static_tex := PixelArt.load_texture(
		static_path,
		GameTuning.MICRO_SPRITE_NATIVE_SIZE,
		_sprite_brighten_for_path(static_path),
	)
	if static_tex == null:
		return {}
	var src_w := maxi(static_tex.get_width(), 1)
	return {
		"texture": static_tex,
		"frame_w": src_w,
		"frame_count": 1,
		"animated": false,
		"scale": 1.0,
	}


func _sprite_brighten_for_path(path: String) -> float:
	if path.contains("/v2/"):
		return 1.0
	return GameTuning.MICRO_SPRITE_BRIGHTEN


func _setup_queen_sprite() -> void:
	var queen_path := SpritePaths.ant_sprite("queen_micro")
	var tex := PixelArt.load_texture(queen_path, GameTuning.MICRO_SPRITE_NATIVE_SIZE, _sprite_brighten_for_path(queen_path))
	if tex == null:
		tex = PixelArt.load_texture("res://assets/sprites/queen.png", GameTuning.MICRO_SPRITE_NATIVE_SIZE, GameTuning.MICRO_SPRITE_BRIGHTEN)
	queen_sprite.texture = tex
	queen_sprite.position = Vector2(
		(ROOM_QUEEN.position.x + ROOM_QUEEN.size.x * 0.5) * _tile_px,
		(ROOM_QUEEN.position.y + ROOM_QUEEN.size.y * 0.5) * _tile_px,
	)
	queen_sprite.centered = true


func _paint_citadel() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var tile := CitadelTile.FLOOR
			if x == 0 or x == GRID_W - 1 or y == 0 or y == GRID_H - 1:
				tile = CitadelTile.WALL
			elif ROOM_QUEEN.has_point(Vector2i(x, y)):
				tile = CitadelTile.QUEEN
			elif ROOM_NURSERY.has_point(Vector2i(x, y)):
				tile = CitadelTile.NURSERY
			elif ROOM_ARMORY.has_point(Vector2i(x, y)):
				tile = CitadelTile.ARMORY
			elif y == ROOM_CORRIDOR.position.y and x >= ROOM_CORRIDOR.position.x and x < ROOM_CORRIDOR.position.x + ROOM_CORRIDOR.size.x:
				tile = CitadelTile.CORRIDOR
			floor_map.set_cell(Vector2i(x, y), 0, _citadel_tileset.tile_to_atlas(tile))


func _on_ant_spawned(ant_type: int) -> void:
	_spawn_ant_visual(ant_type)


func _sync_ant_visuals() -> void:
	for child in ants_root.get_children():
		child.queue_free()
	_ants.clear()
	for i in GameState.gatherer_count:
		_spawn_ant_visual(AntType.GATHERER)
	for i in GameState.builder_count:
		_spawn_ant_visual(AntType.BUILDER)
	var soldiers_to_show := mini(GameState.free_soldiers, _max_visible_soldiers)
	for i in soldiers_to_show:
		_spawn_ant_visual(AntType.SOLDIER)


func _spawn_ant_visual(ant_type: int) -> void:
	var sprite_data: Dictionary = _ant_sprites.get(ant_type, {})
	var tex: Texture2D = sprite_data.get("texture")
	if tex == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	var display_scale: float = sprite_data.get("scale", 1.0)
	sprite.scale = Vector2(display_scale, display_scale)
	if sprite_data.get("animated", false):
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, sprite_data.frame_w, tex.get_height())
	var room := _room_for_type(ant_type)
	var pos := _random_point_in_room(room)
	sprite.position = pos
	ants_root.add_child(sprite)
	_ants.append({
		"sprite": sprite,
		"type": ant_type,
		"room": room,
		"target": _random_point_in_room(room),
		"frame": 0.0,
		"frame_w": sprite_data.get("frame_w", _tile_px),
		"frame_count": sprite_data.get("frame_count", 1),
		"animated": sprite_data.get("animated", false),
	})


func _room_for_type(ant_type: int) -> Rect2i:
	match ant_type:
		AntType.GATHERER:
			return ROOM_NURSERY
		AntType.BUILDER:
			return ROOM_CORRIDOR
		_:
			return ROOM_ARMORY


func _random_point_in_room(room: Rect2i) -> Vector2:
	var x := randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
	var y := randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
	return Vector2(x * _tile_px + _tile_px * 0.5, y * _tile_px + _tile_px * 0.5)


func _process(delta: float) -> void:
	_update_ants(delta)
	if _flash_time > 0.0:
		_flash_time -= delta
		var t := _flash_time / 0.5
		queen_overlay.modulate = Color(1, 0.3, 0.3, t * 0.6)
		if _flash_time <= 0.0:
			queen_overlay.visible = false


func _update_ants(delta: float) -> void:
	const SPEED := 36.0
	for ant in _ants:
		var sprite: Sprite2D = ant.sprite
		var target: Vector2 = ant.target
		var pos: Vector2 = sprite.position
		if pos.distance_to(target) < 3.0:
			ant.target = _random_point_in_room(ant.room)
			target = ant.target
		sprite.position = pos.move_toward(target, SPEED * delta)
		ant.frame += delta * 8.0
		if ant.animated and ant.frame_count > 1:
			var frame_idx: int = int(ant.frame) % int(ant.frame_count)
			sprite.region_rect = Rect2(frame_idx * ant.frame_w, 0, ant.frame_w, sprite.texture.get_height())


func _on_breach(_damage: int) -> void:
	_flash_time = 0.5
	queen_overlay.visible = true
	queen_overlay.position = Vector2(ROOM_QUEEN.position.x * _tile_px, ROOM_QUEEN.position.y * _tile_px)
	queen_overlay.size = Vector2(ROOM_QUEEN.size.x * _tile_px, ROOM_QUEEN.size.y * _tile_px)
