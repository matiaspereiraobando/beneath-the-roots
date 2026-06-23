extends RefCounted

const AntType = preload("res://scripts/data/ant_types.gd").Type
const EMPTY_SLOT := preload("res://scripts/data/ant_types.gd").EMPTY_SLOT

var _gatherer_timer: float = 0.0
var _upkeep_timer: float = 0.0


func update(delta: float) -> void:
	if GameState.level_data.is_empty():
		return
	if not GameState.is_playing():
		return
	_tick_satiety(delta)
	_tick_queen_spawn(delta)
	_tick_gatherers(delta)
	_tick_ant_upkeep(delta)
	_tick_dig_jobs(delta)
	_tick_build_jobs(delta)
	_tick_mine_rearm_jobs(delta)
	if GameState.invasion_active():
		GameState.try_auto_feed()


func _tick_satiety(delta: float) -> void:
	if not GameState.invasion_active():
		return
	GameState.set_satiety(GameState.queen_satiety - GameTuning.SATIETY_DECAY_RATE * delta)


func _tick_queen_spawn(delta: float) -> void:
	if GameState.nursery_queue.is_empty() or GameState.nursery_queue[0] == EMPTY_SLOT:
		return
	GameState.queen_spawn_timer -= delta
	if GameState.queen_spawn_timer > 0.0:
		return
	var interval := GameState.queen_spawn_interval()
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


func _tick_ant_upkeep(delta: float) -> void:
	var ant_count := (
		GameState.gatherer_count
		+ GameState.builder_count
		+ GameState.free_soldiers
		+ GameState.assigned_soldier_count()
	)
	if ant_count <= 0:
		return
	_upkeep_timer -= delta
	if _upkeep_timer > 0.0:
		return
	_upkeep_timer = GameTuning.ANT_UPKEEP_INTERVAL
	var cost := (
		GameState.gatherer_count * GameTuning.GATHERER_UPKEEP
		+ GameState.builder_count * GameTuning.BUILDER_UPKEEP
		+ (GameState.free_soldiers + GameState.assigned_soldier_count()) * GameTuning.SOLDIER_UPKEEP
	)
	GameState.pay_biomass_up_to(cost)


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


func _tick_build_jobs(delta: float) -> void:
	if GameState.build_jobs.is_empty():
		return
	var completed: Array[int] = []
	for job in GameState.build_jobs:
		job.progress = float(job.progress) + delta
		if float(job.progress) >= float(job.duration):
			completed.append(int(job.id))
	for job_id in completed:
		GameState.complete_structure_build(job_id)


func _tick_mine_rearm_jobs(delta: float) -> void:
	if GameState.mine_rearm_jobs.is_empty():
		return
	var completed: Array[int] = []
	for job in GameState.mine_rearm_jobs:
		job.progress = float(job.progress) + delta
		if float(job.progress) >= float(job.duration):
			completed.append(int(job.mine_id))
	for mine_id in completed:
		GameState.mine_rearm_jobs = GameState.mine_rearm_jobs.filter(
			func(j): return int(j.mine_id) != mine_id
		)
		GameState.complete_mine_rearm(mine_id)
