extends Node2D

@onready var terrain: TileMapLayer = $Terrain
@onready var enemies_root: Node2D = $Enemies
@onready var towers_root: Node2D = $Towers
@onready var projectiles_root: Node2D = $Projectiles
@onready var tower_menu: PanelContainer = $TowerMenu

var _pathfinding := GridPathfinding.new()
var _wave_manager := WaveManager.new()
var _combat := CombatSystem.new()
var _enemy_sprites: Dictionary = {}
var _tower_sprites: Dictionary = {}
var _projectile_sprites: Dictionary = {}
var _selected_tower: Dictionary = {}
var _textures: Dictionary = {}


func _ready() -> void:
	terrain.tile_set = PlaceholderTilesets.build_macro_tileset()
	_load_textures()
	tower_menu.visible = false
	_wire_signals()
	call_deferred("_bootstrap_level")


func _bootstrap_level() -> void:
	if GameState.level_data.is_empty():
		return
	_load_level()


func _wire_signals() -> void:
	GameState.level_loaded.connect(func(_id): _load_level())
	GameState.enemy_spawned.connect(_on_enemy_spawned)
	GameState.enemy_killed.connect(_on_enemy_removed)
	GameState.enemy_reached_end.connect(_on_enemy_removed)
	GameState.tower_placed.connect(_on_tower_placed)
	GameState.projectiles_changed.connect(_sync_projectiles)
	$TowerMenu/Buttons/AddBtn.pressed.connect(_on_add_soldier)
	$TowerMenu/Buttons/RemoveBtn.pressed.connect(_on_remove_soldier)
	$TowerMenu/Buttons/CloseBtn.pressed.connect(_hide_tower_menu)


func _load_textures() -> void:
	_textures["spitter"] = _load_tex("res://assets/sprites/spitter.png")
	_textures["skitter"] = _load_tex("res://assets/sprites/skitter.png")
	_textures["chitin"] = _load_tex("res://assets/sprites/skitter.png")


func _load_tex(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _load_level() -> void:
	_enemy_sprites.clear()
	_tower_sprites.clear()
	_projectile_sprites.clear()
	enemies_root.get_children().queue_free()
	towers_root.get_children().queue_free()
	projectiles_root.get_children().queue_free()
	_paint_level(GameState.level_data)
	_pathfinding.setup_from_level(GameState.level_data)
	_wave_manager.setup(_pathfinding)
	_combat.setup(_pathfinding)
	for tower in GameState.towers:
		_on_tower_placed(tower)


func _paint_level(level: Dictionary) -> void:
	terrain.clear()
	var cells: Array = level.cells
	for y in cells.size():
		for x in cells[y].size():
			var tile: int = cells[y][x]
			terrain.set_cell(
				Vector2i(x, y),
				0,
				PlaceholderTilesets.macro_tile_to_atlas(tile)
			)


func _process(delta: float) -> void:
	if GameState.level_data.is_empty():
		return
	_wave_manager.update(delta)
	_combat.update(delta)
	_sync_enemy_positions()
	_sync_projectiles()


func handle_world_click(world_pos: Vector2) -> void:
	if GameState.phase == GameState.Phase.WON or GameState.phase == GameState.Phase.LOST:
		return
	var cell := _pathfinding.world_to_tile(world_pos)
	var tower := GameState.get_tower_at(cell)
	if not tower.is_empty():
		_show_tower_menu(tower, world_pos)
		return
	_hide_tower_menu()
	if GameState.phase == GameState.Phase.BUILD:
		if GameState.place_spitter(cell):
			pass


func _show_tower_menu(tower: Dictionary, world_pos: Vector2) -> void:
	_selected_tower = tower
	tower_menu.visible = true
	tower_menu.position = world_pos + Vector2(8, -40)
	$TowerMenu/Info.text = "Spitter  Soldiers: %d/%d" % [
		tower.soldiers, GameTuning.TOWER_BASE_SLOTS
	]


func _hide_tower_menu() -> void:
	tower_menu.visible = false
	_selected_tower = {}


func _on_add_soldier() -> void:
	if _selected_tower.is_empty():
		return
	GameState.assign_soldier(_selected_tower)
	_show_tower_menu(_selected_tower, tower_menu.position - Vector2(8, -40))


func _on_remove_soldier() -> void:
	if _selected_tower.is_empty():
		return
	GameState.remove_soldier(_selected_tower)
	_show_tower_menu(_selected_tower, tower_menu.position - Vector2(8, -40))


func _on_enemy_spawned(enemy: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _textures.get(enemy.type, _textures.skitter)
	sprite.position = enemy.position
	sprite.scale = Vector2(1.5, 1.5) if enemy.type == "chitin" else Vector2(2, 2)
	if enemy.type == "chitin":
		sprite.modulate = Color(0.7, 0.55, 0.45)
	enemies_root.add_child(sprite)
	_enemy_sprites[enemy.id] = sprite


func _on_enemy_removed(enemy: Dictionary) -> void:
	if _enemy_sprites.has(enemy.id):
		_enemy_sprites[enemy.id].queue_free()
		_enemy_sprites.erase(enemy.id)


func _on_tower_placed(tower: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _textures.get("spitter")
	sprite.position = _pathfinding.tile_center(Vector2i(tower.tile_x, tower.tile_y))
	sprite.scale = Vector2(2, 2)
	towers_root.add_child(sprite)
	_tower_sprites[tower.id] = sprite


func _sync_enemy_positions() -> void:
	for enemy in GameState.enemies:
		if _enemy_sprites.has(enemy.id):
			_enemy_sprites[enemy.id].position = enemy.position


func _sync_projectiles() -> void:
	var live: Dictionary = {}
	for proj in GameState.projectiles:
		live[proj.id] = true
		if not _projectile_sprites.has(proj.id):
			var dot := ColorRect.new()
			dot.size = Vector2(6, 6)
			dot.color = Color(0.42, 1, 0.29)
			dot.position = Vector2(proj.x - 3, proj.y - 3)
			projectiles_root.add_child(dot)
			_projectile_sprites[proj.id] = dot
		else:
			_projectile_sprites[proj.id].position = Vector2(proj.x - 3, proj.y - 3)
	for id in _projectile_sprites.keys():
		if not live.has(id):
			_projectile_sprites[id].queue_free()
			_projectile_sprites.erase(id)
