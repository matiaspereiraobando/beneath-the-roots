extends RefCounted
class_name CombatSystem

var pathfinding: GridPathfinding
var _tower_cooldowns: Dictionary = {}


func setup(pf: GridPathfinding) -> void:
	pathfinding = pf


func update(delta: float) -> void:
	if GameState.phase != GameState.Phase.WAVE:
		return
	for tower in GameState.towers:
		_update_tower(tower, delta)
	_update_projectiles(delta)


func _update_tower(tower: Dictionary, delta: float) -> void:
	var tid: int = tower.id
	var cd: float = _tower_cooldowns.get(tid, 0.0)
	cd -= delta
	if cd > 0.0:
		_tower_cooldowns[tid] = cd
		return
	var center := pathfinding.tile_center(Vector2i(tower.tile_x, tower.tile_y))
	var target := _find_target(center, GameTuning.SPITTER_RANGE)
	if target.is_empty():
		_tower_coldowns_set(tid, 0.1)
		return
	var dmg := _tower_damage(tower)
	var fire_rate := _tower_fire_rate(tower)
	GameState.add_projectile({
		"id": GameState.next_projectile_id(),
		"x": center.x,
		"y": center.y,
		"target_id": target.id,
		"damage": dmg,
		"speed": GameTuning.PROJECTILE_SPEED,
	})
	_tower_cooldowns[tid] = 1.0 / fire_rate


func _tower_coldowns_set(tid: int, val: float) -> void:
	_tower_cooldowns[tid] = val


func _tower_damage(tower: Dictionary) -> float:
	return GameTuning.SPITTER_DAMAGE + tower.soldiers * GameTuning.SOLDIER_DPS_BONUS


func _tower_fire_rate(tower: Dictionary) -> float:
	return GameTuning.SPITTER_FIRE_RATE * (1.0 + tower.soldiers * GameTuning.SOLDIER_FIRE_RATE_BONUS)


func _find_target(from: Vector2, range_px: float) -> Dictionary:
	var best: Dictionary = {}
	var best_prog := -1.0
	for enemy in GameState.enemies:
		var dist := from.distance_to(enemy.position)
		if dist > range_px:
			continue
		if enemy.path_progress > best_prog:
			best_prog = enemy.path_progress
			best = enemy
	return best


func _update_projectiles(delta: float) -> void:
	var to_remove: Array = []
	for proj in GameState.projectiles:
		var target := _enemy_by_id(proj.target_id)
		if target.is_empty():
			to_remove.append(proj)
			continue
		var dir := (target.position - Vector2(proj.x, proj.y)).normalized()
		var step := proj.speed * delta
		proj.x += dir.x * step
		proj.y += dir.y * step
		if Vector2(proj.x, proj.y).distance_to(target.position) < 8.0:
			target.hp -= proj.damage
			to_remove.append(proj)
			if target.hp <= 0:
				GameState.kill_enemy(target)
	if not to_remove.is_empty():
		GameState.remove_projectiles(to_remove)


func _enemy_by_id(id: int) -> Dictionary:
	for enemy in GameState.enemies:
		if enemy.id == id:
			return enemy
	return {}
