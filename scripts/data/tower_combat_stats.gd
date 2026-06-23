extends RefCounted
class_name TowerCombatStats

const PlacementRules = preload("res://scripts/systems/placement.gd")
const TowerCatalog = preload("res://scripts/data/tower_catalog.gd")

const MOD_COLOR_POS := "#4ade80"
const MOD_COLOR_NEG := "#f87171"


static func aura_multipliers(tower: Dictionary, pathfinding: GridPathfinding) -> Dictionary:
	var damage_mult := 1.0
	var fire_rate_mult := 1.0
	if tower.is_empty() or pathfinding == null:
		return {"damage_mult": damage_mult, "fire_rate_mult": fire_rate_mult}
	var tower_center := PlacementRules.tower_world_center(tower, pathfinding)
	for other in GameState.towers:
		if other.type != "gland":
			continue
		var gland_center := PlacementRules.tower_world_center(other, pathfinding)
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


static func base_damage(tower_type: String) -> float:
	return float(GameTuning.tower_stat(tower_type, "damage", GameTuning.SPITTER_DAMAGE))


static func base_fire_rate(tower_type: String) -> float:
	return float(GameTuning.tower_stat(tower_type, "fire_rate", GameTuning.SPITTER_FIRE_RATE))


static func base_dps(tower_type: String) -> float:
	return base_damage(tower_type) * base_fire_rate(tower_type)


static func tower_damage(tower: Dictionary, pathfinding: GridPathfinding) -> float:
	var tower_type := str(tower.type)
	var aura := aura_multipliers(tower, pathfinding)
	return (
		base_damage(tower_type) + int(tower.get("soldiers", 0)) * GameTuning.SOLDIER_DPS_BONUS
	) * aura.damage_mult


static func tower_fire_rate(tower: Dictionary, pathfinding: GridPathfinding) -> float:
	var tower_type := str(tower.type)
	var rate: float = base_fire_rate(tower_type) * (
		1.0 + int(tower.get("soldiers", 0)) * GameTuning.SOLDIER_FIRE_RATE_BONUS
	)
	var aura := aura_multipliers(tower, pathfinding)
	rate *= aura.fire_rate_mult
	if GameState.queen_satiety < GameTuning.STARVE_THRESHOLD:
		rate *= GameTuning.STARVE_FIRE_RATE_MULT
	return rate


static func effective_dps(tower: Dictionary, pathfinding: GridPathfinding) -> float:
	return tower_damage(tower, pathfinding) * tower_fire_rate(tower, pathfinding)


static func menu_title(tower: Dictionary) -> String:
	return TowerCatalog.display_name(str(tower.type))


static func menu_stats_bbcode(tower: Dictionary, pathfinding: GridPathfinding) -> String:
	var tower_type := str(tower.type)
	if tower_type == "gland":
		return _gland_stats_bbcode()
	var lines: PackedStringArray = []
	lines.append(TowerCatalog.attack_type(tower_type))
	lines.append("Range: %.1f tiles" % TowerCatalog.range_tiles(tower_type))
	var base := base_dps(tower_type)
	var effective := effective_dps(tower, pathfinding)
	lines.append(_format_stat_with_delta("DPS", effective, effective - base))
	lines.append("Soldiers: %d/%d" % [int(tower.get("soldiers", 0)), GameTuning.TOWER_BASE_SLOTS])
	match tower_type:
		"crusher":
			var splash_tiles := float(GameTuning.tower_stat("crusher", "splash_radius", 90.0)) / float(GameTuning.TILE_SIZE)
			lines.append("Splash: %.1f tiles" % splash_tiles)
		"needle":
			var pierce: int = int(GameTuning.tower_stat("needle", "pierce", 3))
			lines.append("Pierce: %d targets" % pierce)
	return "\n".join(lines)


static func _gland_stats_bbcode() -> String:
	var lines: PackedStringArray = []
	lines.append(TowerCatalog.attack_type("gland"))
	lines.append("Aura range: %.1f tiles" % TowerCatalog.range_tiles("gland"))
	var dmg_bonus: float = float(GameTuning.tower_stat("gland", "aura_damage", 0.25)) * 100.0
	var rate_bonus: float = float(GameTuning.tower_stat("gland", "aura_fire_rate", 0.2)) * 100.0
	lines.append("Buff: +%.0f%% dmg, +%.0f%% fire rate" % [dmg_bonus, rate_bonus])
	return "\n".join(lines)


static func _format_stat_with_delta(label: String, value: float, delta: float) -> String:
	return "%s: %.1f%s" % [label, value, _format_delta_bbcode(delta)]


static func _format_delta_bbcode(delta: float) -> String:
	if absf(delta) < 0.05:
		return ""
	var color := MOD_COLOR_POS if delta > 0.0 else MOD_COLOR_NEG
	var sign := "+" if delta > 0.0 else ""
	return " [color=%s](%s%.1f)[/color]" % [color, sign, delta]
