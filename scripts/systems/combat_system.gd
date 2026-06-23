extends RefCounted
class_name CombatSystem

const PlacementRules = preload("res://scripts/systems/placement.gd")
const TowerCombatStats = preload("res://scripts/data/tower_combat_stats.gd")
const ProjectileSprites = preload("res://scripts/util/projectile_sprites.gd")

var pathfinding: GridPathfinding
var _tower_cooldowns: Dictionary = {}


func setup(pf: GridPathfinding) -> void:
	pathfinding = pf


func update(delta: float) -> void:
	if not GameState.is_playing():
		return
	for tower in GameState.towers:
		_update_tower(tower, delta)
	_update_mines(delta)
	_update_projectiles(delta)


func _update_tower(tower: Dictionary, delta: float) -> void:
	var tower_type: String = tower.type
	if tower_type == "gland":
		return
	if not TowerCombatStats.tower_is_operational(tower):
		return
	var tid: int = tower.id
	var cd: float = _tower_cooldowns.get(tid, 0.0)
	cd -= delta
	if cd > 0.0:
		_tower_cooldowns[tid] = cd
		return
	var center := PlacementRules.tower_world_center(tower, pathfinding)
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
	GameState.add_projectile({
		"id": GameState.next_projectile_id(),
		"x": center.x,
		"y": center.y,
		"target_id": target.id,
		"damage": _tower_damage(tower),
		"speed": GameTuning.PROJECTILE_SPEED,
		"type": "crusher",
		"splash_radius": GameTuning.tower_stat("crusher", "splash_radius", 90.0),
	})
	GameState.emit_tower_fired(tid)
	_tower_cooldowns[tid] = 1.0 / _tower_fire_rate(tower)


func _fire_needle(tower: Dictionary, center: Vector2, range_px: float, tid: int) -> void:
	var target := _find_rearmost_target(center, range_px)
	if target.is_empty():
		_tower_cooldowns[tid] = 0.1
		return
	var dmg: float = _tower_damage(tower)
	target.hp = float(target.hp) - dmg
	if target.hp <= 0:
		GameState.kill_enemy(target)
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
					"type": "mine_explode",
					"x": center.x,
					"y": center.y,
					"max_life": TowerSprites.mine_explode_duration(),
				})
				if enemy.hp <= 0:
					GameState.kill_enemy(enemy)
				break


func _tower_damage(tower: Dictionary) -> float:
	return TowerCombatStats.tower_damage(tower, pathfinding)


func _tower_fire_rate(tower: Dictionary) -> float:
	return TowerCombatStats.tower_fire_rate(tower, pathfinding)


func _aura_multipliers_for_tower(tower: Dictionary) -> Dictionary:
	return TowerCombatStats.aura_multipliers(tower, pathfinding)


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


func _find_rearmost_target(from: Vector2, range_px: float) -> Dictionary:
	var best: Dictionary = {}
	var best_prog: float = INF
	for enemy in GameState.enemies:
		var pos: Vector2 = enemy.position
		var dist: float = from.distance_to(pos)
		if dist > range_px:
			continue
		var prog: float = float(enemy.path_progress)
		if prog < best_prog:
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
			var proj_type := str(proj.get("type", "spitter"))
			var hit_pos := Vector2(float(proj.x), float(proj.y))
			match proj_type:
				"crusher":
					_apply_crusher_splash(
						hit_pos,
						float(proj.damage),
						float(proj.get("splash_radius", 90.0)),
					)
				_:
					GameState.add_combat_effect({
						"type": "spitter_splat",
						"x": hit_pos.x,
						"y": hit_pos.y,
						"max_life": ProjectileSprites.spitter_splat_duration(),
					})
					target.hp = float(target.hp) - float(proj.damage)
					if target.hp <= 0:
						GameState.kill_enemy(target)
			to_remove.append(proj)
	if not to_remove.is_empty():
		GameState.remove_projectiles(to_remove)


func _enemy_by_id(id: int) -> Dictionary:
	for enemy in GameState.enemies:
		if enemy.id == id:
			return enemy
	return {}


func _apply_crusher_splash(hit_pos: Vector2, dmg: float, splash_radius: float) -> void:
	for enemy in GameState.enemies.duplicate():
		if hit_pos.distance_to(enemy.position) <= splash_radius:
			enemy.hp = float(enemy.hp) - dmg
			if enemy.hp <= 0:
				GameState.kill_enemy(enemy)
	GameState.add_combat_effect({
		"type": "crusher_splat",
		"x": hit_pos.x,
		"y": hit_pos.y,
		"max_life": ProjectileSprites.crusher_splat_duration(),
	})
	GameState.add_combat_effect({
		"type": "splash",
		"x": hit_pos.x,
		"y": hit_pos.y,
		"radius": splash_radius,
		"color": TowerSprites.effect_color("crusher"),
		"max_life": 0.35,
	})
