extends Node
## Singleton gameplay state — single source of truth.

enum Phase { BUILD, WAVE, WON, LOST }

signal biomass_changed(value: int)
signal phase_changed(phase: Phase)
signal queen_hp_changed(current: int, maximum: int)
signal queen_satiety_changed(value: float)

var biomass: int = 50
var queen_hp: int = 100
var queen_max_hp: int = 100
var queen_satiety: float = 100.0
var phase: Phase = Phase.BUILD
var wave_index: int = 0
var build_timer: float = 40.0
var current_level_id: String = "level1_breach"

func reset_for_level(level_id: String, starting_biomass: int = 50, max_hp: int = 100) -> void:
	current_level_id = level_id
	biomass = starting_biomass
	queen_max_hp = max_hp
	queen_hp = max_hp
	queen_satiety = 100.0
	phase = Phase.BUILD
	wave_index = 0
	build_timer = 40.0
	_emit_all()

func set_phase(next: Phase) -> void:
	phase = next
	phase_changed.emit(phase)

func add_biomass(amount: int) -> void:
	biomass += amount
	biomass_changed.emit(biomass)

func spend_biomass(amount: int) -> bool:
	if biomass < amount:
		return false
	biomass -= amount
	biomass_changed.emit(biomass)
	return true

func damage_queen(amount: int) -> void:
	queen_hp = maxi(0, queen_hp - amount)
	queen_hp_changed.emit(queen_hp, queen_max_hp)
	if queen_hp <= 0:
		set_phase(Phase.LOST)

func set_satiety(value: float) -> void:
	queen_satiety = clampf(value, 0.0, 100.0)
	queen_satiety_changed.emit(queen_satiety)

func _emit_all() -> void:
	biomass_changed.emit(biomass)
	queen_hp_changed.emit(queen_hp, queen_max_hp)
	queen_satiety_changed.emit(queen_satiety)
	phase_changed.emit(phase)
