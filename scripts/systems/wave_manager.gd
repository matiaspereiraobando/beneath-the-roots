extends RefCounted
class_name WaveManager

var pathfinding: GridPathfinding


func setup(pf: GridPathfinding) -> void:
	pathfinding = pf


func update(delta: float) -> void:
	if not GameState.is_playing():
		return
	GameState.tick_next_wave_timer(delta)
	_try_spawn(delta)
	_move_enemies(delta)
	GameState.check_win_condition()


func _try_spawn(delta: float) -> void:
	var spent: float = delta
	while true:
		var entry: Dictionary = GameState.pop_ready_spawn(spent)
		spent = 0.0
		if entry.is_empty():
			break
		var spawn_data: Dictionary = GameState.level_data.spawnTile
		var spawn := Vector2i(int(spawn_data.x), int(spawn_data.y))
		var path := pathfinding.get_path_to_citadel(spawn)
		if path.is_empty():
			path = PackedVector2Array([pathfinding.tile_center(spawn)])
		var wave_idx: int = int(entry.get("wave_idx", -1))
		GameState.spawn_enemy(str(entry.type), path, wave_idx)


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
