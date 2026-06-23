extends RefCounted
class_name TowerCatalog

const ENTRIES := {
	"spitter": {
		"name": "Spitter",
		"attack_type": "Single target",
		"description": "Fires acid spores at the furthest enemy in range.",
	},
	"crusher": {
		"name": "Crusher",
		"attack_type": "Area splash",
		"description": "Blasts the furthest enemy and damages all foes in a short splash radius.",
	},
	"needle": {
		"name": "Needle",
		"attack_type": "Piercing beam",
		"description": "Cuts a narrow beam through up to three enemies along the path.",
	},
	"gland": {
		"name": "Gland",
		"attack_type": "Support aura",
		"description": "Buffs nearby towers with extra damage and fire rate. Does not attack.",
	},
	"mine": {
		"name": "Fungal mine",
		"attack_type": "Proximity trap",
		"description": "Arms on a tunnel tile and detonates when an enemy steps on it. Click a spent mine to rearm it manually.",
	},
}


static func display_name(type: String) -> String:
	return ENTRIES.get(type, {}).get("name", type.capitalize())


static func attack_type(type: String) -> String:
	return ENTRIES.get(type, {}).get("attack_type", "")


static func description(type: String) -> String:
	return ENTRIES.get(type, {}).get("description", "")


static func base_dps(type: String) -> float:
	var dmg: float = float(GameTuning.tower_stat(type, "damage", 0.0))
	var rate: float = float(GameTuning.tower_stat(type, "fire_rate", 0.0))
	return dmg * rate


static func range_tiles(type: String) -> float:
	var range_px: float = 0.0
	if type == "mine":
		range_px = GameTuning.MINE_TRIGGER_RADIUS
	else:
		range_px = float(GameTuning.tower_stat(type, "range", 0.0))
	return range_px / float(GameTuning.TILE_SIZE)


static func cost(type: String) -> int:
	if type == "mine":
		return GameTuning.MINE_COST
	return GameTuning.tower_cost(type)


static func footprint_label(type: String) -> String:
	var size: Vector2i = GameTuning.STRUCTURE_FOOTPRINTS.get(type, Vector2i(2, 2))
	if size.x == 1 and size.y == 1:
		return "1×1 tunnel tile"
	return "%d×%d rock chamber" % [size.x, size.y]


static func stat_lines(type: String) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("Footprint: %s" % footprint_label(type))
	lines.append("Cost: %d biomass" % cost(type))
	lines.append("Build time: %.0fs" % GameTuning.structure_build_duration(type))

	if type == "mine":
		lines.append("Damage: %d (once per trigger)" % GameTuning.MINE_DAMAGE)
		lines.append("Rearm: manual, %.0fs" % GameTuning.MINE_REARM_DURATION)
		lines.append("Trigger: on-path proximity")
		return lines

	if type == "gland":
		var aura_range: float = range_tiles(type)
		lines.append("Aura range: %.1f tiles" % aura_range)
		var dmg_bonus: float = float(GameTuning.tower_stat("gland", "aura_damage", 0.25)) * 100.0
		var rate_bonus: float = float(GameTuning.tower_stat("gland", "aura_fire_rate", 0.2)) * 100.0
		lines.append("Buff: +%.0f%% dmg, +%.0f%% fire rate" % [dmg_bonus, rate_bonus])
		return lines

	var range_label := "Range: %.1f tiles" % range_tiles(type)
	lines.append(range_label)

	var dps := base_dps(type)
	if dps > 0.0:
		lines.append("DPS: %.1f" % dps)

	match type:
		"crusher":
			var splash_tiles := float(GameTuning.tower_stat("crusher", "splash_radius", 90.0)) / float(GameTuning.TILE_SIZE)
			lines.append("Splash: %.1f tiles" % splash_tiles)
		"needle":
			var pierce: int = int(GameTuning.tower_stat("needle", "pierce", 3))
			lines.append("Pierce: %d targets" % pierce)

	lines.append("Soldiers: %d slots (+DPS & fire rate)" % GameTuning.TOWER_BASE_SLOTS)
	return lines
