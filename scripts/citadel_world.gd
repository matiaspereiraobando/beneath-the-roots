extends Node2D

const AntType = preload("res://scripts/data/ant_types.gd").Type
const CitadelTile = preload("res://scripts/util/placeholder_tilesets.gd").CitadelTile

@onready var floor_map: TileMapLayer = $FloorMap
@onready var ants_root: Node2D = $Ants
@onready var queen_sprite: Sprite2D = $QueenSprite
@onready var queen_overlay: ColorRect = $QueenOverlay

const GRID_W := 19
const GRID_H := 29
const TILE_PX := 16

const ROOM_NURSERY := Rect2i(2, 8, 6, 7)
const ROOM_ARMORY := Rect2i(11, 8, 6, 7)
const ROOM_QUEEN := Rect2i(6, 20, 7, 9)
const ROOM_CORRIDOR := Rect2i(4, 15, 11, 1)

var _flash_time := 0.0
var _citadel_tileset
var _ant_sprites: Dictionary = {}
var _ants: Array[Dictionary] = []
var _max_visible_soldiers := 8


func _ready() -> void:
	_citadel_tileset = load("res://scripts/util/citadel_tileset.gd").new()
	floor_map.tile_set = _citadel_tileset.tile_set
	_load_ant_textures()
	_paint_citadel()
	_setup_queen_sprite()
	GameState.citadel_breached.connect(_on_breach)
	GameState.ant_spawned.connect(_on_ant_spawned)
	GameState.level_loaded.connect(func(_id): _sync_ant_visuals())
	queen_overlay.visible = false


func _load_ant_textures() -> void:
	_ant_sprites[AntType.GATHERER] = _load_ant_sprite("gatherer", "res://assets/sprites/gatherer.png")
	_ant_sprites[AntType.BUILDER] = _load_ant_sprite("builder", "res://assets/sprites/builder.png")
	_ant_sprites[AntType.SOLDIER] = _load_ant_sprite("soldier", "res://assets/sprites/soldier_micro.png")


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _load_ant_sprite(base_name: String, static_path: String) -> Dictionary:
	var walk_path := "res://assets/sprites/ants/%s_walk.png" % base_name
	var sheet := _load_tex(walk_path)
	if sheet:
		var frame_w := TILE_PX
		var frame_count := maxi(1, sheet.get_width() / frame_w)
		return {"texture": sheet, "frame_w": frame_w, "frame_count": frame_count, "animated": true}
	var tex := _load_tex(static_path)
	if tex == null:
		return {}
	return {"texture": tex, "frame_w": tex.get_width(), "frame_count": 1, "animated": false}


func _setup_queen_sprite() -> void:
	var tex := _load_tex("res://assets/sprites/queen_micro.png")
	if tex == null:
		tex = _load_tex("res://assets/sprites/queen.png")
	queen_sprite.texture = tex
	queen_sprite.position = Vector2(
		(ROOM_QUEEN.position.x + ROOM_QUEEN.size.x * 0.5) * TILE_PX,
		(ROOM_QUEEN.position.y + ROOM_QUEEN.size.y * 0.5) * TILE_PX,
	)
	queen_sprite.centered = true
	if tex:
		var max_dim := maxf(tex.get_width(), tex.get_height())
		queen_sprite.scale = Vector2.ONE * clampf(48.0 / max_dim, 0.5, 2.0)


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
		"frame_w": sprite_data.get("frame_w", TILE_PX),
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
	return Vector2(x * TILE_PX + TILE_PX * 0.5, y * TILE_PX + TILE_PX * 0.5)


func _process(delta: float) -> void:
	_update_ants(delta)
	if _flash_time > 0.0:
		_flash_time -= delta
		var t := _flash_time / 0.5
		queen_overlay.modulate = Color(1, 0.3, 0.3, t * 0.6)
		if _flash_time <= 0.0:
			queen_overlay.visible = false


func _update_ants(delta: float) -> void:
	const SPEED := 20.0
	for ant in _ants:
		var sprite: Sprite2D = ant.sprite
		var target: Vector2 = ant.target
		var pos: Vector2 = sprite.position
		if pos.distance_to(target) < 2.0:
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
	queen_overlay.position = Vector2(ROOM_QUEEN.position.x * TILE_PX, ROOM_QUEEN.position.y * TILE_PX)
	queen_overlay.size = Vector2(ROOM_QUEEN.size.x * TILE_PX, ROOM_QUEEN.size.y * TILE_PX)
