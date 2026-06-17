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
	_update_mines(delta)
	_update_projectiles(delta)


func _update_tower(tower: Dictionary, delta: float) -> void:
	var tower_type: String = tower.type
	if tower_type == "gland":
		return
	var tid: int = tower.id
	var cd: float = _tower_cooldowns.get(tid, 0.0)
	cd -= delta
	if cd > 0.0:
		_tower_cooldowns[tid] = cd
		return
	var center := pathfinding.tile_center(Vector2i(tower.tile_x, tower.tile_y))
	var range_px: float = GameTuning.tower_stat(tower_type, "range", GameTuning.SPITTER_RANGE)
	match tower_type:
		"crusher":
			_fire_crusher(tower, center, range_px, tid)
		"needle":
			_fire_needle(tower, center, range_px, tid)
		_:
			_fire_spitter(tower, center, range_px, tid)


func _fire_spitter(tower: Dictionary, center: Vector2, range_px: float, tid: int) -> void:
	var target := _find_target(center, range_px)
	if target.is_empty():
		_tower_cooldowns[tid] = 0.1
		return
	GameState.add_projectile({
		"id": GameState.next_projectile_id(),
		"x": center.x,
		"y": center.y,
		"target_id": target.id,
		"damage": _tower_damage(tower),
		"speed": GameTuning.PROJECTILE_SPEED,
		"type": "spitter",
	})
	GameState.emit_tower_fired(tid)
	_tower_cooldowns[tid] = 1.0 / _tower_fire_rate(tower)


func _fire_crusher(tower: Dictionary, center: Vector2, range_px: float, tid: int) -> void:
	var target := _find_target(center, range_px)
	if target.is_empty():
		_tower_cooldowns[tid] = 0.1
		return
	var splash: float = GameTuning.tower_stat("crusher", "splash_radius", 90.0)
	var dmg: float = _tower_damage(tower)
	for enemy in GameState.enemies.duplicate():
		if center.distance_to(enemy.position) <= splash:
			enemy.hp = float(enemy.hp) - dmg
			if enemy.hp <= 0:
				GameState.kill_enemy(enemy)
	GameState.add_combat_effect({
		"type": "splash",
		"x": center.x,
		"y": center.y,
		"radius": splash,
		"color": TowerSprites.effect_color("crusher"),
		"max_life": 0.28,
	})
	GameState.emit_tower_fired(tid)
	_tower_cooldowns[tid] = 1.0 / _tower_fire_rate(tower)


func _fire_needle(tower: Dictionary, center: Vector2, range_px: float, tid: int) -> void:
	var target := _find_target(center, range_px)
	if target.is_empty():
		_tower_cooldowns[tid] = 0.1
		return
	var pierce: int = int(GameTuning.tower_stat("needle", "pierce", 3))
	var hits := _enemies_in_needle_cone(center, target.position, range_px, pierce)
	var dmg: float = _tower_damage(tower)
	for enemy in hits:
		enemy.hp = float(enemy.hp) - dmg
		if enemy.hp <= 0:
			GameState.kill_enemy(enemy)
	GameState.add_combat_effect({
		"type": "beam",
		"x": center.x,
		"y": center.y,
		"tx": target.position.x,
		"ty": target.position.y,
		"color": TowerSprites.effect_color("needle"),
		"max_life": 0.18,
	})
	GameState.emit_tower_fired(tid)
	_tower_cooldowns[tid] = 1.0 / _tower_fire_rate(tower)


func _enemies_in_needle_cone(from: Vector2, toward: Vector2, range_px: float, max_hits: int) -> Array:
	var dir := (toward - from).normalized()
	var candidates: Array = []
	for enemy in GameState.enemies:
		var pos: Vector2 = enemy.position
		if from.distance_to(pos) > range_px:
			continue
		var to_enemy := (pos - from).normalized()
		if dir.dot(to_enemy) < 0.85:
			continue
		candidates.append(enemy)
	candidates.sort_custom(func(a, b): return float(a.path_progress) > float(b.path_progress))
	if candidates.size() > max_hits:
		return candidates.slice(0, max_hits)
	return candidates


func _update_mines(delta: float) -> void:
	for mine in GameState.mines:
		if not mine.armed:
			continue
		var center := pathfinding.tile_center(Vector2i(mine.tile_x, mine.tile_y))
		for enemy in GameState.enemies:
			if center.distance_to(enemy.position) <= GameTuning.MINE_TRIGGER_RADIUS:
				enemy.hp = float(enemy.hp) - GameTuning.MINE_DAMAGE
				GameState.trigger_mine(mine)
				GameState.add_combat_effect({
					"type": "splash",
					"x": center.x,
					"y": center.y,
					"radius": 28.0,
					"color": TowerSprites.effect_color("mine"),
					"max_life": 0.35,
				})
				if enemy.hp <= 0:
					GameState.kill_enemy(enemy)
				break


func _tower_damage(tower: Dictionary) -> float:
	var base: float = GameTuning.tower_stat(tower.type, "damage", GameTuning.SPITTER_DAMAGE)
	var aura := _aura_multipliers_for_tower(tower)
	return (base + tower.soldiers * GameTuning.SOLDIER_DPS_BONUS) * aura.damage_mult


func _tower_fire_rate(tower: Dictionary) -> float:
	var base: float = GameTuning.tower_stat(tower.type, "fire_rate", GameTuning.SPITTER_FIRE_RATE)
	var rate: float = base * (1.0 + tower.soldiers * GameTuning.SOLDIER_FIRE_RATE_BONUS)
	var aura := _aura_multipliers_for_tower(tower)
	rate *= aura.fire_rate_mult
	if GameState.queen_satiety < GameTuning.STARVE_THRESHOLD:
		rate *= GameTuning.STARVE_FIRE_RATE_MULT
	return rate


func _aura_multipliers_for_tower(tower: Dictionary) -> Dictionary:
	var damage_mult := 1.0
	var fire_rate_mult := 1.0
	var tower_center := pathfinding.tile_center(Vector2i(tower.tile_x, tower.tile_y))
	for other in GameState.towers:
		if other.type != "gland":
			continue
		var gland_center := pathfinding.tile_center(Vector2i(other.tile_x, other.tile_y))
		var gland_range: float = GameTuning.tower_stat("gland", "range", 180.0)
		if tower_center.distance_to(gland_center) > gland_range:
			continue
		damage_mult = maxf(
			damage_mult,
			1.0 + float(GameTuning.tower_stat("gland", "aura_damage", 0.25))
		)
		fire_rate_mult = maxf(
			fire_rate_mult,
			1.0 + float(GameTuning.tower_stat("gland", "aura_fire_rate", 0.2))
		)
	return {"damage_mult": damage_mult, "fire_rate_mult": fire_rate_mult}


func _find_target(from: Vector2, range_px: float) -> Dictionary:
	var best: Dictionary = {}
	var best_prog: float = -1.0
	for enemy in GameState.enemies:
		var pos: Vector2 = enemy.position
		var dist: float = from.distance_to(pos)
		if dist > range_px:
			continue
		var prog: float = float(enemy.path_progress)
		if prog > best_prog:
			best_prog = prog
			best = enemy
	return best


func _update_projectiles(delta: float) -> void:
	var to_remove: Array = []
	for proj in GameState.projectiles:
		var target := _enemy_by_id(int(proj.target_id))
		if target.is_empty():
			to_remove.append(proj)
			continue
		var target_pos: Vector2 = target.position
		var proj_pos := Vector2(float(proj.x), float(proj.y))
		var dir := (target_pos - proj_pos).normalized()
		var step: float = float(proj.speed) * delta
		proj.x = float(proj.x) + dir.x * step
		proj.y = float(proj.y) + dir.y * step
		if Vector2(float(proj.x), float(proj.y)).distance_to(target_pos) < 8.0:
			target.hp = float(target.hp) - float(proj.damage)
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
