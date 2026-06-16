extends RefCounted
class_name WaveManager

var pathfinding: GridPathfinding


func setup(pf: GridPathfinding) -> void:
	pathfinding = pf


func update(delta: float) -> void:
	if GameState.phase == GameState.Phase.WON or GameState.phase == GameState.Phase.LOST:
		return
	if GameState.phase == GameState.Phase.BUILD:
		_update_build(delta)
		return
	if GameState.phase == GameState.Phase.WAVE:
		_update_wave(delta)


func _update_build(delta: float) -> void:
	GameState.tick_build_timer(delta)
	if GameState.build_timer <= 0.0:
		_start_wave()


func _start_wave() -> void:
	GameState.start_wave()


func _update_wave(delta: float) -> void:
	_try_spawn(delta)
	_move_enemies(delta)
	_check_wave_complete()


func _try_spawn(delta: float) -> void:
	var spent: float = delta
	while true:
		var type: String = GameState.pop_ready_spawn(spent)
		spent = 0.0
		if type == "":
			break
		var spawn_data: Dictionary = GameState.level_data.spawnTile
		var spawn := Vector2i(int(spawn_data.x), int(spawn_data.y))
		var path := pathfinding.get_path_to_citadel(spawn)
		if path.is_empty():
			path = PackedVector2Array([pathfinding.tile_center(spawn)])
		GameState.spawn_enemy(type, path)


func _move_enemies(delta: float) -> void:
	for enemy in GameState.enemies.duplicate():
		var path: PackedVector2Array = enemy.path
		if path.is_empty():
			continue
		var remaining: float = float(enemy.speed) * delta
		while remaining > 0.0 and int(enemy.path_index) < path.size() - 1:
			var to: Vector2 = path[int(enemy.path_index) + 1]
			var pos: Vector2 = enemy.position
			var dist: float = pos.distance_to(to)
			if dist <= remaining:
				remaining -= dist
				enemy.path_progress = float(enemy.path_progress) + dist
				enemy.path_index = int(enemy.path_index) + 1
				enemy.position = path[int(enemy.path_index)]
			else:
				enemy.position = pos.lerp(to, remaining / dist)
				enemy.path_progress = float(enemy.path_progress) + remaining
				remaining = 0.0
		if int(enemy.path_index) >= path.size() - 1:
			var pos: Vector2 = enemy.position
			var cell := pathfinding.world_to_tile(pos)
			if pathfinding.is_citadel(cell) or pos.distance_to(path[path.size() - 1]) < 6.0:
				GameState.breach_enemy(enemy)


func _check_wave_complete() -> void:
	if GameState.has_pending_spawns():
		return
	if not GameState.enemies.is_empty():
		return
	GameState.finish_wave()
