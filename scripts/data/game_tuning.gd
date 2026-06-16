extends Node
## Combat tuning constants — source: docs/GAME_DESIGN.md

const BUILD_PHASE_DURATION := 40.0
const TILE_SIZE := 32

const MACRO_PAN_SPEED := 400.0

const SPITTER_COST := 40
const SPITTER_RANGE := 288.0
const SPITTER_DAMAGE := 8.0
const SPITTER_FIRE_RATE := 1.2
const TOWER_BASE_SLOTS := 2

const SOLDIER_DPS_BONUS := 2.0
const SOLDIER_FIRE_RATE_BONUS := 0.15

const PROJECTILE_SPEED := 400.0

const ENEMY_STATS := {
	"skitter": {"hp": 30, "speed": 110.0, "damage": 8, "reward": 8},
	"chitin": {"hp": 80, "speed": 60.0, "damage": 15, "reward": 15},
	"scarab": {"hp": 200, "speed": 44.0, "damage": 25, "reward": 40},
}

static func enemy_stat(type: String, key: String):
	return ENEMY_STATS.get(type, ENEMY_STATS.skitter).get(key)
