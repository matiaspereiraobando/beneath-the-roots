extends Node
## Singleton gameplay state — single source of truth.

enum Phase { PLAYING, WON, LOST }

signal biomass_changed(value: int)
signal phase_changed(phase: Phase)
signal queen_hp_changed(current: int, maximum: int)
signal queen_satiety_changed(value: float)
signal next_wave_timer_changed(seconds: float)
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
const PlacementRules = preload("res://scripts/systems/placement.gd")

signal dig_started(cell: Vector2i)
signal dig_completed(cell: Vector2i)
signal structure_build_started(job: Dictionary)
signal structure_build_completed(job: Dictionary)
signal mine_placed(mine: Dictionary)
signal mine_triggered(mine: Dictionary)
signal mine_rearm_started(mine: Dictionary)
signal mine_rearmed(mine: Dictionary)
signal cells_changed(cell: Vector2i)
signal tower_fired(tower_id: int)
signal combat_effects_changed

const EMPTY_SLOT = preload("res://scripts/data/ant_types.gd").EMPTY_SLOT
const NURSERY_SLOTS = preload("res://scripts/data/ant_types.gd").NURSERY_SLOTS

var biomass: int = 50
var queen_hp: int = 100
var queen_max_hp: int = 100
var queen_satiety: float = 100.0
var phase: Phase = Phase.PLAYING
var next_wave_index: int = 0
var next_wave_timer: float = 40.0
var current_level_id: String = "first_breach"
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
var build_jobs: Array = []
var mine_rearm_jobs: Array = []
var projectiles: Array = []
var combat_effects: Array = []

var _next_enemy_id: int = 1
var _next_tower_id: int = 1
var _next_mine_id: int = 1
var _next_build_job_id: int = 1
var _next_projectile_id: int = 1

var _spawn_queue: Array = []
var _wave_enemy_alive: Dictionary = {}
var _wave_spawns_scheduled: Dictionary = {}
var _wave_bonus_awarded: Dictionary = {}


func reset_for_level(level_id: String, starting_biomass: int = 50, max_hp: int = 100) -> void:
	current_level_id = level_id
	level_data = LevelLoader.load_level(level_id)
	if level_data.is_empty():
		push_warning("Using defaults for missing level: %s" % level_id)
		biomass = starting_biomass
		queen_max_hp = max_hp
		free_soldiers = 0
		builder_count = 0
		gatherer_count = 0
	else:
		biomass = level_data.get("startingBiomass", starting_biomass)
		queen_max_hp = level_data.get("queenMaxHp", max_hp)
		free_soldiers = level_data.get("startingSoldiers", 0)
		builder_count = level_data.get("startingBuilders", 0)
		gatherer_count = level_data.get("startingGatherers", 0)
	nursery_queue.clear()
	for i in NURSERY_SLOTS:
		nursery_queue.append(EMPTY_SLOT)
	queen_spawn_timer = 0.0
	queen_hp = queen_max_hp
	queen_satiety = 100.0
	phase = Phase.PLAYING
	next_wave_index = 0
	next_wave_timer = GameTuning.WAVE_INTERVAL
	enemies.clear()
	towers.clear()
	mines.clear()
	dig_jobs.clear()
	build_jobs.clear()
	mine_rearm_jobs.clear()
	projectiles.clear()
	combat_effects.clear()
	_spawn_queue.clear()
	_wave_enemy_alive.clear()
	_wave_spawns_scheduled.clear()
	_wave_bonus_awarded.clear()
	_next_enemy_id = 1
	_next_tower_id = 1
	_next_mine_id = 1
	_next_build_job_id = 1
	_next_projectile_id = 1
	_emit_all()
	level_loaded.emit(level_id)
	soldiers_changed.emit(free_soldiers)
	colony_counts_changed.emit()
	nursery_changed.emit()


func cycle_nursery_slot(index: int) -> void:
	if index <= 0 or index >= NURSERY_SLOTS:
		return
	if nursery_queue[index] == EMPTY_SLOT:
		return
	match nursery_queue[index]:
		AntType.GATHERER:
			nursery_queue[index] = AntType.BUILDER
		AntType.BUILDER:
			nursery_queue[index] = AntType.SOLDIER
		AntType.SOLDIER:
			nursery_queue[index] = AntType.GATHERER
	nursery_changed.emit()


func nursery_filled_count() -> int:
	var count := 0
	for slot in nursery_queue:
		if slot != EMPTY_SLOT:
			count += 1
	return count


func can_enqueue_nursery() -> bool:
	return nursery_filled_count() < NURSERY_SLOTS


func enqueue_nursery_ant(ant_type: int) -> String:
	if ant_type < AntType.GATHERER or ant_type > AntType.SOLDIER:
		return "Invalid ant type."
	if not can_enqueue_nursery():
		return "Nursery queue is full."
	var starting_gestation := nursery_filled_count() == 0
	nursery_queue[nursery_filled_count()] = ant_type
	if starting_gestation:
		queen_spawn_timer = queen_spawn_interval()
	nursery_changed.emit()
	return ""


func queen_spawn_interval() -> float:
	var interval: float = GameTuning.QUEEN_SPAWN_INTERVAL
	if queen_satiety >= GameTuning.WELL_FED_THRESHOLD:
		interval *= GameTuning.WELL_FED_SPAWN_MULT
	return interval


func gestation_remaining_ratio() -> float:
	if nursery_queue.is_empty() or nursery_queue[0] == EMPTY_SLOT:
		return 0.0
	var interval := queen_spawn_interval()
	if interval <= 0.0:
		return 0.0
	return clampf(queen_spawn_timer / interval, 0.0, 1.0)


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
	var err := PlacementRules.can_dig(cell)
	if err != "":
		return err
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
	set_cell_at(cell, MacroCell.TUNNEL)
	builder_count += 1
	colony_counts_changed.emit()
	dig_completed.emit(cell)


func get_dig_jobs() -> Array:
	return dig_jobs


func next_build_job_id() -> int:
	var id := _next_build_job_id
	_next_build_job_id += 1
	return id


func build_job_footprint_cells(job: Dictionary) -> Array[Vector2i]:
	if str(job.get("kind", "")) == "mine":
		return [Vector2i(int(job.tile_x), int(job.tile_y))]
	var size := Vector2i(int(job.get("width", 2)), int(job.get("height", 2)))
	return PlacementRules.footprint_cells(Vector2i(int(job.tile_x), int(job.tile_y)), size)


func is_building_at(cell: Vector2i) -> bool:
	for job in build_jobs:
		if cell in build_job_footprint_cells(job):
			return true
	return false


func get_build_job_at(cell: Vector2i) -> Dictionary:
	for job in build_jobs:
		if cell in build_job_footprint_cells(job):
			return job
	return {}


func _start_structure_build(anchor: Vector2i, structure_type: String, kind: String) -> String:
	if builder_count < 1:
		return "Need a builder ant in the colony."
	var duration := GameTuning.structure_build_duration(structure_type)
	var size := PlacementRules.footprint_for(structure_type)
	var job := {
		"id": next_build_job_id(),
		"kind": kind,
		"structure_type": structure_type,
		"tile_x": anchor.x,
		"tile_y": anchor.y,
		"width": size.x,
		"height": size.y,
		"progress": 0.0,
		"duration": duration,
	}
	builder_count -= 1
	colony_counts_changed.emit()
	build_jobs.append(job)
	structure_build_started.emit(job)
	return ""


func complete_structure_build(job_id: int) -> void:
	var job: Dictionary = {}
	for entry in build_jobs:
		if int(entry.id) == job_id:
			job = entry
			break
	if job.is_empty():
		return
	build_jobs = build_jobs.filter(func(j): return int(j.id) != job_id)
	builder_count += 1
	colony_counts_changed.emit()
	var structure_type := str(job.structure_type)
	if str(job.kind) == "mine":
		var mine := {
			"id": next_mine_id(),
			"tile_x": int(job.tile_x),
			"tile_y": int(job.tile_y),
			"armed": true,
		}
		mines.append(mine)
		mine_placed.emit(mine)
	else:
		var tower := {
			"id": next_tower_id(),
			"type": structure_type,
			"tile_x": int(job.tile_x),
			"tile_y": int(job.tile_y),
			"width": int(job.width),
			"height": int(job.height),
			"soldiers": 0,
		}
		towers.append(tower)
		tower_placed.emit(tower)
	structure_build_completed.emit(job)


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


func is_playing() -> bool:
	return phase == Phase.PLAYING


func invasion_active() -> bool:
	return not enemies.is_empty() or has_pending_spawns()


func tick_next_wave_timer(delta: float) -> void:
	if phase != Phase.PLAYING:
		return
	var waves: Array = level_data.get("waves", [])
	if next_wave_index >= waves.size():
		return
	if next_wave_timer <= 0.0:
		schedule_next_wave()
		return
	next_wave_timer = maxf(0.0, next_wave_timer - delta)
	next_wave_timer_changed.emit(next_wave_timer)
	if next_wave_timer <= 0.0:
		schedule_next_wave()


func schedule_next_wave() -> void:
	var waves: Array = level_data.get("waves", [])
	if next_wave_index >= waves.size():
		return
	var wave_idx := next_wave_index
	append_wave_spawns(wave_idx)
	_wave_spawns_scheduled[wave_idx] = true
	wave_started.emit(wave_idx)
	next_wave_index += 1
	next_wave_timer = GameTuning.WAVE_INTERVAL
	next_wave_timer_changed.emit(next_wave_timer)
	_check_all_waves_spawned_win()


func _check_all_waves_spawned_win() -> void:
	var waves: Array = level_data.get("waves", [])
	if next_wave_index < waves.size():
		return
	if has_pending_spawns() or not enemies.is_empty():
		return
	set_phase(Phase.WON)


func check_win_condition() -> void:
	_check_all_waves_spawned_win()


func add_biomass(amount: int) -> void:
	biomass += amount
	biomass_changed.emit(biomass)


func spend_biomass(amount: int) -> bool:
	if biomass < amount:
		return false
	biomass -= amount
	biomass_changed.emit(biomass)
	return true


func pay_biomass_up_to(amount: int) -> void:
	if amount <= 0:
		return
	var paid := mini(biomass, amount)
	if paid <= 0:
		return
	biomass -= paid
	biomass_changed.emit(biomass)


func assigned_soldier_count() -> int:
	var total := 0
	for tower in towers:
		total += int(tower.soldiers)
	return total


func busy_builder_count() -> int:
	return dig_jobs.size() + build_jobs.size()


func total_builder_count() -> int:
	return builder_count + busy_builder_count()


func total_soldier_count() -> int:
	return free_soldiers + assigned_soldier_count()


func total_gatherer_count() -> int:
	return gatherer_count


func biomass_income_per_second() -> float:
	if gatherer_count <= 0:
		return 0.0
	return (
		float(gatherer_count * GameTuning.GATHERER_BIOMASS_AMOUNT)
		/ GameTuning.GATHERER_BIOMASS_INTERVAL
	)


func biomass_upkeep_per_second() -> float:
	var upkeep := (
		gatherer_count * GameTuning.GATHERER_UPKEEP
		+ builder_count * GameTuning.BUILDER_UPKEEP
		+ (free_soldiers + assigned_soldier_count()) * GameTuning.SOLDIER_UPKEEP
	)
	return float(upkeep) / GameTuning.ANT_UPKEEP_INTERVAL


func biomass_net_per_second() -> float:
	return biomass_income_per_second() - biomass_upkeep_per_second()


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


func get_tower_at(cell: Vector2i) -> Dictionary:
	return PlacementRules.tower_covering(cell)


func get_mine_at(cell: Vector2i) -> Dictionary:
	for mine in mines:
		if mine.tile_x == cell.x and mine.tile_y == cell.y:
			return mine
	return {}


func get_tower_by_id(tower_id: int) -> Dictionary:
	for tower in towers:
		if int(tower.id) == tower_id:
			return tower
	return {}


func get_mine_by_id(mine_id: int) -> Dictionary:
	for mine in mines:
		if mine.id == mine_id:
			return mine
	return {}


func is_rearming_mine(mine_id: int) -> bool:
	for job in mine_rearm_jobs:
		if int(job.mine_id) == mine_id:
			return true
	return false


func is_rearming_at(cell: Vector2i) -> bool:
	for job in mine_rearm_jobs:
		var mine := get_mine_by_id(int(job.mine_id))
		if not mine.is_empty() and mine.tile_x == cell.x and mine.tile_y == cell.y:
			return true
	return false


func start_mine_rearm(mine: Dictionary) -> String:
	if not is_playing():
		return "Cannot rearm right now."
	if mine.is_empty():
		return "No mine selected."
	if mine.armed:
		return "Mine is already armed."
	if is_rearming_mine(mine.id):
		return "Already rearming."
	mine_rearm_jobs.append({
		"mine_id": mine.id,
		"progress": 0.0,
		"duration": GameTuning.MINE_REARM_DURATION,
	})
	mine_rearm_started.emit(mine)
	return ""


func complete_mine_rearm(mine_id: int) -> void:
	var mine := get_mine_by_id(mine_id)
	if mine.is_empty():
		return
	mine.armed = true
	mine_rearmed.emit(mine)


func place_tower(anchor: Vector2i, tower_type: String) -> String:
	if tower_type == "mine":
		return "Select mine with key 5, then click a tunnel tile."
	var err := PlacementRules.can_place_tower(anchor, tower_type)
	if err != "":
		return err
	var cost: int = GameTuning.TOWER_COSTS.get(tower_type, GameTuning.SPITTER_COST)
	if biomass < cost:
		return "Need %d biomass (you have %d)." % [cost, biomass]
	if not spend_biomass(cost):
		return "Need %d biomass." % cost
	return _start_structure_build(anchor, tower_type, "tower")


func place_spitter(anchor: Vector2i) -> String:
	return place_tower(anchor, "spitter")


func place_mine(cell: Vector2i) -> String:
	var err := PlacementRules.can_place_mine(cell)
	if err != "":
		return err
	var cost := GameTuning.MINE_COST
	if biomass < cost:
		return "Need %d biomass (you have %d)." % [cost, biomass]
	if not spend_biomass(cost):
		return "Need %d biomass." % cost
	return _start_structure_build(cell, "mine", "mine")


func repath_enemies(pathfinding: GridPathfinding) -> void:
	for enemy in enemies:
		var cell := pathfinding.world_to_tile(enemy.position)
		var new_path := pathfinding.get_path_to_citadel(cell)
		if new_path.is_empty():
			continue
		var best_idx := 0
		var best_dist: float = enemy.position.distance_squared_to(new_path[0])
		for i in range(1, new_path.size()):
			var d: float = enemy.position.distance_squared_to(new_path[i])
			if d < best_dist:
				best_dist = d
				best_idx = i
		enemy.path = new_path
		enemy.path_index = best_idx
		var progress := 0.0
		for i in range(best_idx):
			progress += new_path[i].distance_to(new_path[i + 1])
		if best_idx < new_path.size():
			progress += new_path[best_idx].distance_to(enemy.position)
		enemy.path_progress = progress


func trigger_mine(mine: Dictionary) -> void:
	if mine.is_empty() or not mine.armed:
		return
	mine.armed = false
	mine_triggered.emit(mine)


func assign_soldier(tower: Dictionary) -> bool:
	if tower.is_empty():
		return false
	return assign_soldier_to_id(int(tower.get("id", -1)))


func assign_soldier_to_id(tower_id: int) -> bool:
	var tower := get_tower_by_id(tower_id)
	if tower.is_empty():
		return false
	if str(tower.type) == "mine":
		return false
	if free_soldiers <= 0:
		return false
	var assigned := int(tower.get("soldiers", 0))
	if assigned >= GameTuning.TOWER_BASE_SLOTS:
		return false
	tower.soldiers = assigned + 1
	free_soldiers -= 1
	tower_soldiers_changed.emit(tower)
	soldiers_changed.emit(free_soldiers)
	colony_counts_changed.emit()
	return true


func remove_soldier(tower: Dictionary) -> bool:
	if tower.is_empty():
		return false
	return remove_soldier_from_id(int(tower.get("id", -1)))


func remove_soldier_from_id(tower_id: int) -> bool:
	var tower := get_tower_by_id(tower_id)
	if tower.is_empty():
		return false
	var assigned := int(tower.get("soldiers", 0))
	if assigned <= 0:
		return false
	tower.soldiers = assigned - 1
	free_soldiers += 1
	tower_soldiers_changed.emit(tower)
	soldiers_changed.emit(free_soldiers)
	colony_counts_changed.emit()
	return true


func spawn_enemy(type: String, path: PackedVector2Array, wave_idx: int = -1) -> Dictionary:
	var stats: Dictionary = GameTuning.ENEMY_STATS.get(type, GameTuning.ENEMY_STATS.skitter)
	var enemy := {
		"id": next_enemy_id(),
		"type": type,
		"hp": stats.hp,
		"max_hp": stats.hp,
		"speed": stats.speed,
		"damage": stats.damage,
		"reward": stats.reward,
		"wave_idx": wave_idx,
		"path": path,
		"path_index": 0,
		"path_progress": 0.0,
		"position": path[0] if path.size() > 0 else Vector2.ZERO,
	}
	enemies.append(enemy)
	if wave_idx >= 0:
		_wave_enemy_alive[wave_idx] = int(_wave_enemy_alive.get(wave_idx, 0)) + 1
	enemy_spawned.emit(enemy)
	return enemy


func kill_enemy(enemy: Dictionary) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	add_biomass(enemy.reward)
	_on_enemy_removed(enemy)
	enemy_killed.emit(enemy)


func breach_enemy(enemy: Dictionary) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	damage_queen(enemy.damage)
	_on_enemy_removed(enemy)
	enemy_reached_end.emit(enemy)


func _on_enemy_removed(enemy: Dictionary) -> void:
	var wave_idx: int = int(enemy.get("wave_idx", -1))
	if wave_idx >= 0:
		_wave_enemy_alive[wave_idx] = maxi(0, int(_wave_enemy_alive.get(wave_idx, 1)) - 1)
		_try_award_wave_bonus(wave_idx)
	_check_all_waves_spawned_win()


func append_wave_spawns(wave_idx: int) -> void:
	var waves: Array = level_data.get("waves", [])
	if wave_idx >= waves.size():
		return
	var wave: Dictionary = waves[wave_idx]
	var wait := 0.0
	for group in wave.get("enemies", []):
		if typeof(group) != TYPE_DICTIONARY:
			continue
		wait += float(group.get("delay", 0.0))
		var count := int(group.get("count", 0))
		var interval := float(group.get("interval", 0.0))
		var enemy_type := str(group.get("type", "skitter"))
		for _i in count:
			_spawn_queue.append({
				"type": enemy_type,
				"timer": wait,
				"wave_idx": wave_idx,
			})
			wait = interval


func _try_award_wave_bonus(wave_idx: int) -> void:
	if _wave_bonus_awarded.get(wave_idx, false):
		return
	if not _wave_spawns_scheduled.get(wave_idx, false):
		return
	if _has_pending_spawns_for_wave(wave_idx):
		return
	if int(_wave_enemy_alive.get(wave_idx, 0)) > 0:
		return
	var waves: Array = level_data.get("waves", [])
	if wave_idx >= waves.size():
		return
	var bonus: int = waves[wave_idx].get("clearBonus", 0)
	_wave_bonus_awarded[wave_idx] = true
	if bonus > 0:
		add_biomass(bonus)
		wave_cleared.emit(bonus)


func _has_pending_spawns_for_wave(wave_idx: int) -> bool:
	for entry in _spawn_queue:
		if int(entry.get("wave_idx", -1)) == wave_idx:
			return true
	return false


func get_wave_count() -> int:
	return level_data.get("waves", []).size()


func get_active_wave_number() -> int:
	return clampi(next_wave_index, 1, maxi(1, get_wave_count()))


func add_projectile(proj: Dictionary) -> void:
	projectiles.append(proj)
	projectiles_changed.emit()


func remove_projectiles(to_remove: Array) -> void:
	if to_remove.is_empty():
		return
	for p in to_remove:
		projectiles.erase(p)
	projectiles_changed.emit()


func add_combat_effect(effect: Dictionary) -> void:
	var copy := effect.duplicate()
	copy["life"] = float(copy.get("life", copy.get("max_life", 0.35)))
	combat_effects.append(copy)
	combat_effects_changed.emit()


func tick_combat_effects(delta: float) -> void:
	if combat_effects.is_empty():
		return
	var changed := false
	for i in range(combat_effects.size() - 1, -1, -1):
		combat_effects[i].life = float(combat_effects[i].life) - delta
		if combat_effects[i].life <= 0.0:
			combat_effects.remove_at(i)
			changed = true
	if changed:
		combat_effects_changed.emit()


func emit_tower_fired(tower_id: int) -> void:
	tower_fired.emit(tower_id)


func has_pending_spawns() -> bool:
	return not _spawn_queue.is_empty()


func tick_spawn_timers(delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	_spawn_queue[0].timer = float(_spawn_queue[0].timer) - delta


func pop_ready_spawn(_delta: float = 0.0) -> Dictionary:
	if _spawn_queue.is_empty():
		return {}
	if float(_spawn_queue[0].timer) > 0.0:
		return {}
	var entry: Dictionary = _spawn_queue[0]
	_spawn_queue.remove_at(0)
	return entry


func get_wave_clear_bonus(wave_idx: int) -> int:
	var waves: Array = level_data.get("waves", [])
	if wave_idx >= waves.size():
		return 0
	return waves[wave_idx].get("clearBonus", 0)


func _emit_all() -> void:
	biomass_changed.emit(biomass)
	queen_hp_changed.emit(queen_hp, queen_max_hp)
	queen_satiety_changed.emit(queen_satiety)
	phase_changed.emit(phase)
	next_wave_timer_changed.emit(next_wave_timer)
	soldiers_changed.emit(free_soldiers)
	colony_counts_changed.emit()
	nursery_changed.emit()
