extends Node
## Combat tuning constants — source: docs/GAME_DESIGN.md

const BUILD_PHASE_DURATION := 40.0
const TILE_SIZE := 16

const SPITTER_COST := 40
const SPITTER_RANGE := 140.0
const SPITTER_DAMAGE := 8.0
const SPITTER_FIRE_RATE := 1.2
const TOWER_BASE_SLOTS := 2

const SOLDIER_DPS_BONUS := 2.0
const SOLDIER_FIRE_RATE_BONUS := 0.15

const PROJECTILE_SPEED := 200.0

const ENEMY_STATS := {
	"skitter": {"hp": 30, "speed": 55.0, "damage": 8, "reward": 8},
	"chitin": {"hp": 80, "speed": 30.0, "damage": 15, "reward": 15},
	"scarab": {"hp": 200, "speed": 22.0, "damage": 25, "reward": 40},
}

static func enemy_stat(type: String, key: String):
	return ENEMY_STATS.get(type, ENEMY_STATS.skitter).get(key)
