extends Node
## Combat tuning constants — source: docs/GAME_DESIGN.md

const WAVE_INTERVAL := 40.0
const BUILD_PHASE_DURATION := WAVE_INTERVAL
const TILE_SIZE := 32
const MICRO_TILE_SIZE := 32
const MICRO_SPRITE_NATIVE_SIZE := 64
const MICRO_SPRITE_SOURCE_SIZE := 16
const HUD_ICON_SIZE := 24
const UI_ICON_NATIVE_SIZE := 64
const UI_ICON_BRIGHTEN := 1.2
const MICRO_SPRITE_BRIGHTEN := 1.15

const MACRO_PAN_SPEED := 400.0

const MACRO_DEPTH_MIN_BRIGHTNESS := 0.5
const MACRO_DEPTH_COOL_TINT := 1.0

const DIG_DURATION := 4.0
const DIG_COST := 15

const STRUCTURE_FOOTPRINTS := {
	"spitter": Vector2i(2, 2),
	"crusher": Vector2i(2, 2),
	"needle": Vector2i(2, 2),
	"gland": Vector2i(2, 2),
	"mine": Vector2i(1, 1),
}

const TOWER_BASE_SLOTS := 2
const SOLDIER_DPS_BONUS := 2.0
const SOLDIER_FIRE_RATE_BONUS := 0.15
const PROJECTILE_SPEED := 400.0
const STRUCTURE_IDLE_FRAME_SEC := 0.5

const TOWER_COSTS := {
	"spitter": 40,
	"crusher": 50,
	"needle": 45,
	"gland": 35,
}
const MINE_COST := 25
const MINE_DAMAGE := 40
const MINE_TRIGGER_RADIUS := 20.0

const TOWER_STATS := {
	"spitter": {
		"range": 288.0,
		"damage": 8.0,
		"fire_rate": 1.2,
	},
	"crusher": {
		"range": 140.0,
		"damage": 12.0,
		"fire_rate": 0.8,
		"splash_radius": 90.0,
	},
	"needle": {
		"range": 224.0,
		"damage": 6.0,
		"fire_rate": 1.5,
		"pierce": 3,
	},
	"gland": {
		"range": 180.0,
		"damage": 0.0,
		"fire_rate": 0.0,
		"aura_damage": 0.25,
		"aura_fire_rate": 0.2,
	},
}

const TOWER_PLACEHOLDER_COLORS := {
	"spitter": Color(0.29, 0.42, 0.23),
	"crusher": Color(0.42, 0.29, 0.23),
	"needle": Color(0.35, 0.35, 0.42),
	"gland": Color(0.48, 0.29, 0.55),
}

# Legacy aliases
const SPITTER_COST := 40
const SPITTER_RANGE := 288.0
const SPITTER_DAMAGE := 8.0
const SPITTER_FIRE_RATE := 1.2

const GATHERER_BIOMASS_INTERVAL := 2.0
const GATHERER_BIOMASS_AMOUNT := 3

const QUEEN_SPAWN_INTERVAL := 10.0
const WELL_FED_SPAWN_MULT := 0.65
const SATIETY_DECAY_RATE := 4.0
const FEED_COST := 15
const FEED_RESTORE := 35.0
const AUTO_FEED_THRESHOLD := 50.0
const AUTO_FEED_EFFICIENCY := 0.5
const WELL_FED_THRESHOLD := 70.0
const STARVE_THRESHOLD := 30.0
const STARVE_FIRE_RATE_MULT := 0.65

const ENEMY_STATS := {
	"skitter": {"hp": 30, "speed": 110.0, "damage": 8, "reward": 8},
	"chitin": {"hp": 80, "speed": 60.0, "damage": 15, "reward": 15},
	"scarab": {"hp": 200, "speed": 44.0, "damage": 25, "reward": 40},
}

static func enemy_stat(type: String, key: String):
	return ENEMY_STATS.get(type, ENEMY_STATS.skitter).get(key)


static func tower_stat(type: String, key: String, default = null):
	return TOWER_STATS.get(type, TOWER_STATS.spitter).get(key, default)


static func tower_cost(type: String) -> int:
	return TOWER_COSTS.get(type, SPITTER_COST)
