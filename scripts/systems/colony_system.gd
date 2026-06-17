extends RefCounted

const AntType = preload("res://scripts/data/ant_types.gd").Type
const EMPTY_SLOT := preload("res://scripts/data/ant_types.gd").EMPTY_SLOT

var _gatherer_timer: float = 0.0


func update(delta: float) -> void:
	if GameState.level_data.is_empty():
		return
	if GameState.phase == GameState.Phase.WON or GameState.phase == GameState.Phase.LOST:
		return
	_tick_satiety(delta)
	_tick_queen_spawn(delta)
	_tick_gatherers(delta)
	_tick_dig_jobs(delta)
	if GameState.phase == GameState.Phase.WAVE:
		GameState.try_auto_feed()


func _tick_satiety(delta: float) -> void:
	if GameState.phase != GameState.Phase.WAVE:
		return
	GameState.set_satiety(GameState.queen_satiety - GameTuning.SATIETY_DECAY_RATE * delta)


func _tick_queen_spawn(delta: float) -> void:
	if GameState.phase != GameState.Phase.BUILD and GameState.phase != GameState.Phase.WAVE:
		return
	GameState.queen_spawn_timer -= delta
	if GameState.queen_spawn_timer > 0.0:
		return
	var interval := GameTuning.QUEEN_SPAWN_INTERVAL
	if GameState.queen_satiety >= GameTuning.WELL_FED_THRESHOLD:
		interval *= GameTuning.WELL_FED_SPAWN_MULT
	GameState.queen_spawn_timer = interval
	var ant_type: int = GameState.dequeue_nursery_ant()
	if ant_type == EMPTY_SLOT:
		return
	GameState.spawn_ant(ant_type)


func _tick_gatherers(delta: float) -> void:
	if GameState.gatherer_count <= 0:
		return
	_gatherer_timer -= delta
	if _gatherer_timer > 0.0:
		return
	_gatherer_timer = GameTuning.GATHERER_BIOMASS_INTERVAL
	GameState.add_biomass(GameState.gatherer_count * GameTuning.GATHERER_BIOMASS_AMOUNT)


func _tick_dig_jobs(delta: float) -> void:
	if GameState.dig_jobs.is_empty():
		return
	var completed: Array[Vector2i] = []
	for job in GameState.dig_jobs:
		job.progress = float(job.progress) + delta
		if float(job.progress) >= float(job.duration):
			completed.append(Vector2i(job.cell_x, job.cell_y))
	for cell in completed:
		GameState.dig_jobs = GameState.dig_jobs.filter(
			func(j): return not (j.cell_x == cell.x and j.cell_y == cell.y)
		)
		GameState.complete_dig(cell)
