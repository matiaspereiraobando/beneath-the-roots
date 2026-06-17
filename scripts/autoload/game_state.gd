extends Node
## Singleton gameplay state — single source of truth.

enum Phase { BUILD, WAVE, WON, LOST }

signal biomass_changed(value: int)
signal phase_changed(phase: Phase)
signal queen_hp_changed(current: int, maximum: int)
signal queen_satiety_changed(value: float)
signal build_timer_changed(seconds: float)
signal level_loaded(level_id: String)
signal enemy_spawned(enemy: Dictionary)
signal enemy_killed(enemy: Dictionary)
signal enemy_reached_end(enemy: Dictionary)
signal citadel_breached(damage: int)
signal tower_placed(tower: Dictionary)
signal tower_soldiers_changed(tower: Dictionary)
signal wave_started(index: int)
signal wave_cleared(bonus: int)
signal soldiers_changed(free_count: int)
signal projectiles_changed
signal nursery_changed
signal colony_counts_changed
signal ant_spawned(ant_type: int)

const MacroCell = preload("res://scripts/data/macro_tiles.gd").Cell
const AntType = preload("res://scripts/data/ant_types.gd").Type

signal dig_started(cell: Vector2i)
signal dig_completed(cell: Vector2i)
signal mine_placed(mine: Dictionary)
signal mine_triggered(mine: Dictionary)
signal cells_changed(cell: Vector2i)

const EMPTY_SLOT = preload("res://scripts/data/ant_types.gd").EMPTY_SLOT
const NURSERY_SLOTS = preload("res://scripts/data/ant_types.gd").NURSERY_SLOTS

var biomass: int = 50
var queen_hp: int = 100
var queen_max_hp: int = 100
var queen_satiety: float = 100.0
var phase: Phase = Phase.BUILD
var wave_index: int = 0
var build_timer: float = 40.0
var current_level_id: String = "level1_breach"
var free_soldiers: int = 0
var gatherer_count: int = 0
var builder_count: int = 0
var nursery_queue: Array = [-1, -1, -1, -1, -1]
var queen_spawn_timer: float = 0.0

var level_data: Dictionary = {}
var enemies: Array = []
var towers: Array = []
var mines: Array = []
var dig_jobs: Array = []
var projectiles: Array = []

var _next_enemy_id: int = 1
var _next_tower_id: int = 1
var _next_mine_id: int = 1
var _next_projectile_id: int = 1

var _spawn_queue: Array = []
var _wave_enemies_remaining: int = 0


func reset_for_level(level_id: String, starting_biomass: int = 50, max_hp: int = 100) -> void:
	current_level_id = level_id
	level_data = LevelLoader.load_level(level_id)
	if level_data.is_empty():
		push_warning("Using defaults for missing level: %s" % level_id)
		biomass = starting_biomass
		queen_max_hp = max_hp
		free_soldiers = 0
	else:
		biomass = level_data.get("startingBiomass", starting_biomass)
		queen_max_hp = level_data.get("queenMaxHp", max_hp)
		free_soldiers = level_data.get("startingSoldiers", 0)
	gatherer_count = 0
	builder_count = 0
	nursery_queue.clear()
	for i in NURSERY_SLOTS:
		nursery_queue.append(EMPTY_SLOT)
	queen_spawn_timer = GameTuning.QUEEN_SPAWN_INTERVAL
	queen_hp = queen_max_hp
	queen_satiety = 100.0
	phase = Phase.BUILD
	wave_index = 0
	build_timer = GameTuning.BUILD_PHASE_DURATION
	enemies.clear()
	towers.clear()
	mines.clear()
	dig_jobs.clear()
	projectiles.clear()
	_spawn_queue.clear()
	_wave_enemies_remaining = 0
	_next_enemy_id = 1
	_next_tower_id = 1
	_next_mine_id = 1
	_next_projectile_id = 1
	_emit_all()
	level_loaded.emit(level_id)
	soldiers_changed.emit(free_soldiers)
	colony_counts_changed.emit()
	nursery_changed.emit()


func cycle_nursery_slot(index: int) -> void:
	if index < 0 or index >= NURSERY_SLOTS:
		return
	var current: int = nursery_queue[index]
	match current:
		EMPTY_SLOT:
			nursery_queue[index] = AntType.GATHERER
		AntType.GATHERER:
			nursery_queue[index] = AntType.BUILDER
		AntType.BUILDER:
			nursery_queue[index] = AntType.SOLDIER
		_:
			nursery_queue[index] = EMPTY_SLOT
	nursery_changed.emit()


func dequeue_nursery_ant() -> int:
	for i in NURSERY_SLOTS:
		if nursery_queue[i] == EMPTY_SLOT:
			continue
		var ant_type: int = nursery_queue[i]
		for j in range(i, NURSERY_SLOTS - 1):
			nursery_queue[j] = nursery_queue[j + 1]
		nursery_queue[NURSERY_SLOTS - 1] = EMPTY_SLOT
		nursery_changed.emit()
		return ant_type
	return EMPTY_SLOT


func has_open_build_slot() -> bool:
	var cells: Array = level_data.get("cells", [])
	if cells.is_empty():
		return false
	for y in cells.size():
		for x in cells[y].size():
			if cells[y][x] != MacroCell.BUILD:
				continue
			if get_tower_at(Vector2i(x, y)).is_empty():
				return true
	return false


func get_cell_at(cell: Vector2i) -> int:
	var cells: Array = level_data.get("cells", [])
	if cell.y < 0 or cell.y >= cells.size():
		return -1
	if cell.x < 0 or cell.x >= cells[cell.y].size():
		return -1
	return cells[cell.y][cell.x]


func set_cell_at(cell: Vector2i, cell_type: int) -> void:
	var cells: Array = level_data.get("cells", [])
	if cell.y < 0 or cell.y >= cells.size():
		return
	if cell.x < 0 or cell.x >= cells[cell.y].size():
		return
	cells[cell.y][cell.x] = cell_type
	cells_changed.emit(cell)


func is_digging_at(cell: Vector2i) -> bool:
	for job in dig_jobs:
		if job.cell_x == cell.x and job.cell_y == cell.y:
			return true
	return false


func start_dig(cell: Vector2i) -> String:
	if phase != Phase.BUILD:
		return "Dig only during BUILD phase."
	if get_cell_at(cell) != MacroCell.SOFT_EARTH:
		return "Click soft earth (brown tile) to dig."
	if is_digging_at(cell):
		return "Already digging here."
	if builder_count < 1:
		return "Need a builder ant in the colony."
	var cost := GameTuning.DIG_COST
	if biomass < cost:
		return "Need %d biomass to dig (you have %d)." % [cost, biomass]
	if not spend_biomass(cost):
		return "Need %d biomass to dig." % cost
	builder_count -= 1
	colony_counts_changed.emit()
	dig_jobs.append({
		"cell_x": cell.x,
		"cell_y": cell.y,
		"progress": 0.0,
		"duration": GameTuning.DIG_DURATION,
	})
	dig_started.emit(cell)
	return ""


func complete_dig(cell: Vector2i) -> void:
	set_cell_at(cell, MacroCell.BUILD)
	builder_count += 1
	colony_counts_changed.emit()
	dig_completed.emit(cell)


func get_dig_jobs() -> Array:
	return dig_jobs


func next_mine_id() -> int:
	var id := _next_mine_id
	_next_mine_id += 1
	return id


func feed_queen() -> bool:
	if not spend_biomass(GameTuning.FEED_COST):
		return false
	set_satiety(queen_satiety + GameTuning.FEED_RESTORE)
	return true


func try_auto_feed() -> void:
	if queen_satiety >= GameTuning.AUTO_FEED_THRESHOLD:
		return
	if biomass < GameTuning.FEED_COST:
		return
	if not spend_biomass(GameTuning.FEED_COST):
		return
	var restore: float = GameTuning.FEED_RESTORE * GameTuning.AUTO_FEED_EFFICIENCY
	set_satiety(queen_satiety + restore)


func spawn_ant(ant_type: int) -> void:
	match ant_type:
		AntType.GATHERER:
			gatherer_count += 1
		AntType.BUILDER:
			builder_count += 1
		AntType.SOLDIER:
			free_soldiers += 1
			soldiers_changed.emit(free_soldiers)
	colony_counts_changed.emit()
	ant_spawned.emit(ant_type)


func set_phase(next: Phase) -> void:
	phase = next
	phase_changed.emit(phase)


func tick_build_timer(delta: float) -> void:
	if phase != Phase.BUILD or build_timer <= 0.0:
		return
	build_timer = maxf(0.0, build_timer - delta)
	build_timer_changed.emit(build_timer)


func add_biomass(amount: int) -> void:
	biomass += amount
	biomass_changed.emit(biomass)


func spend_biomass(amount: int) -> bool:
	if biomass < amount:
		return false
	biomass -= amount
	biomass_changed.emit(biomass)
	return true


func damage_queen(amount: int) -> void:
	queen_hp = maxi(0, queen_hp - amount)
	queen_hp_changed.emit(queen_hp, queen_max_hp)
	citadel_breached.emit(amount)
	if queen_hp <= 0:
		set_phase(Phase.LOST)


func set_satiety(value: float) -> void:
	queen_satiety = clampf(value, 0.0, 100.0)
	queen_satiety_changed.emit(queen_satiety)


func next_enemy_id() -> int:
	var id := _next_enemy_id
	_next_enemy_id += 1
	return id


func next_tower_id() -> int:
	var id := _next_tower_id
	_next_tower_id += 1
	return id


func next_projectile_id() -> int:
	var id := _next_projectile_id
	_next_projectile_id += 1
	return id


func get_build_slot_at(cell: Vector2i) -> bool:
	return get_cell_at(cell) == MacroCell.BUILD


func get_tower_at(cell: Vector2i) -> Dictionary:
	for tower in towers:
		if tower.tile_x == cell.x and tower.tile_y == cell.y:
			return tower
	return {}


func get_mine_at(cell: Vector2i) -> Dictionary:
	for mine in mines:
		if mine.tile_x == cell.x and mine.tile_y == cell.y:
			return mine
	return {}


func place_tower(cell: Vector2i, tower_type: String) -> String:
	if phase != Phase.BUILD:
		return "Structures can only be placed during BUILD phase."
	if tower_type == "mine":
		return "Select a tunnel tile for mines (press 5)."
	if not GameTuning.TOWER_COSTS.has(tower_type):
		return "Unknown structure type."
	if not get_build_slot_at(cell):
		return "Click a build tile (green ring)."
	if not get_tower_at(cell).is_empty():
		return "A structure is already on this tile."
	var cost: int = GameTuning.TOWER_COSTS.get(tower_type, GameTuning.SPITTER_COST)
	if biomass < cost:
		return "Need %d biomass (you have %d)." % [cost, biomass]
	if not spend_biomass(cost):
		return "Need %d biomass." % cost
	var tower := {
		"id": next_tower_id(),
		"type": tower_type,
		"tile_x": cell.x,
		"tile_y": cell.y,
		"soldiers": 0,
	}
	towers.append(tower)
	tower_placed.emit(tower)
	return ""


func place_spitter(cell: Vector2i) -> String:
	return place_tower(cell, "spitter")


func place_mine(cell: Vector2i) -> String:
	if phase != Phase.BUILD:
		return "Mines can only be placed during BUILD phase."
	if get_cell_at(cell) != MacroCell.TUNNEL:
		return "Mines go on tunnel tiles (press 5, then click path)."
	if not get_mine_at(cell).is_empty():
		return "A mine is already on this tile."
	var cost := GameTuning.MINE_COST
	if biomass < cost:
		return "Need %d biomass (you have %d)." % [cost, biomass]
	if not spend_biomass(cost):
		return "Need %d biomass." % cost
	var mine := {
		"id": next_mine_id(),
		"tile_x": cell.x,
		"tile_y": cell.y,
		"armed": true,
	}
	mines.append(mine)
	mine_placed.emit(mine)
	return ""


func rearm_mines() -> void:
	for mine in mines:
		mine.armed = true


func trigger_mine(mine: Dictionary) -> void:
	if mine.is_empty() or not mine.armed:
		return
	mine.armed = false
	mine_triggered.emit(mine)


func assign_soldier(tower: Dictionary) -> bool:
	if tower.is_empty():
		return false
	if tower.type == "gland":
		return false
	if free_soldiers <= 0:
		return false
	if tower.soldiers >= GameTuning.TOWER_BASE_SLOTS:
		return false
	tower.soldiers += 1
	free_soldiers -= 1
	tower_soldiers_changed.emit(tower)
	soldiers_changed.emit(free_soldiers)
	return true


func remove_soldier(tower: Dictionary) -> bool:
	if tower.is_empty() or tower.soldiers <= 0:
		return false
	tower.soldiers -= 1
	free_soldiers += 1
	tower_soldiers_changed.emit(tower)
	soldiers_changed.emit(free_soldiers)
	return true


func spawn_enemy(type: String, path: PackedVector2Array) -> Dictionary:
	var stats: Dictionary = GameTuning.ENEMY_STATS.get(type, GameTuning.ENEMY_STATS.skitter)
	var enemy := {
		"id": next_enemy_id(),
		"type": type,
		"hp": stats.hp,
		"max_hp": stats.hp,
		"speed": stats.speed,
		"damage": stats.damage,
		"reward": stats.reward,
		"path": path,
		"path_index": 0,
		"path_progress": 0.0,
		"position": path[0] if path.size() > 0 else Vector2.ZERO,
	}
	enemies.append(enemy)
	_wave_enemies_remaining += 1
	enemy_spawned.emit(enemy)
	return enemy


func kill_enemy(enemy: Dictionary) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	add_biomass(enemy.reward)
	_wave_enemies_remaining = maxi(0, _wave_enemies_remaining - 1)
	enemy_killed.emit(enemy)


func breach_enemy(enemy: Dictionary) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	damage_queen(enemy.damage)
	_wave_enemies_remaining = maxi(0, _wave_enemies_remaining - 1)
	enemy_reached_end.emit(enemy)


func queue_wave_spawns() -> void:
	_spawn_queue.clear()
	_wave_enemies_remaining = 0
	var waves: Array = level_data.get("waves", [])
	if wave_index >= waves.size():
		return
	var wave: Dictionary = waves[wave_index]
	var delay := 0.0
	for group in wave.enemies:
		delay += group.get("delay", 0.0)
		for i in group.count:
			_spawn_queue.append({"type": group.type, "timer": delay})
			delay += group.interval


func start_wave() -> void:
	var waves: Array = level_data.get("waves", [])
	if wave_index >= waves.size():
		set_phase(Phase.WON)
		return
	set_phase(Phase.WAVE)
	queue_wave_spawns()
	wave_started.emit(wave_index)


func finish_wave() -> void:
	var bonus := get_wave_clear_bonus()
	add_biomass(bonus)
	wave_cleared.emit(bonus)
	advance_wave_or_win()


func add_projectile(proj: Dictionary) -> void:
	projectiles.append(proj)
	projectiles_changed.emit()


func remove_projectiles(to_remove: Array) -> void:
	if to_remove.is_empty():
		return
	for p in to_remove:
		projectiles.erase(p)
	projectiles_changed.emit()


func has_pending_spawns() -> bool:
	return not _spawn_queue.is_empty()


func pop_ready_spawn(delta: float) -> String:
	if _spawn_queue.is_empty():
		return ""
	_spawn_queue[0].timer -= delta
	if _spawn_queue[0].timer > 0.0:
		return ""
	var type: String = _spawn_queue[0].type
	_spawn_queue.remove_at(0)
	return type


func get_wave_clear_bonus() -> int:
	var waves: Array = level_data.get("waves", [])
	if wave_index >= waves.size():
		return 0
	return waves[wave_index].get("clearBonus", 0)


func advance_wave_or_win() -> void:
	var waves: Array = level_data.get("waves", [])
	wave_index += 1
	if wave_index >= waves.size():
		set_phase(Phase.WON)
		return
	phase = Phase.BUILD
	build_timer = GameTuning.BUILD_PHASE_DURATION
	build_timer_changed.emit(build_timer)
	rearm_mines()
	phase_changed.emit(phase)


func _emit_all() -> void:
	biomass_changed.emit(biomass)
	queen_hp_changed.emit(queen_hp, queen_max_hp)
	queen_satiety_changed.emit(queen_satiety)
	phase_changed.emit(phase)
	build_timer_changed.emit(build_timer)
	soldiers_changed.emit(free_soldiers)
	colony_counts_changed.emit()
	nursery_changed.emit()
