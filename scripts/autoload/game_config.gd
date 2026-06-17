extends Node
## Layout constants and tuning references.

const VIEWPORT_WIDTH := 960
const VIEWPORT_HEIGHT := 540
const HUD_HEIGHT := 56
const COLONY_RAIL_WIDTH := 80
const COLONY_DRAWER_WIDTH := 365


func macro_width() -> int:
	return VIEWPORT_WIDTH - COLONY_RAIL_WIDTH


func colony_drawer_width() -> int:
	return COLONY_DRAWER_WIDTH


func colony_rail_width() -> int:
	return COLONY_RAIL_WIDTH


func panel_height() -> int:
	return VIEWPORT_HEIGHT - HUD_HEIGHT
