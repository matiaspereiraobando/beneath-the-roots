extends Node
## Layout constants and tuning references.

const VIEWPORT_WIDTH := 960
const VIEWPORT_HEIGHT := 540
const HUD_HEIGHT := 56
const MACRO_RATIO := 0.62

func macro_width() -> int:
	return int(VIEWPORT_WIDTH * MACRO_RATIO)

func micro_width() -> int:
	return VIEWPORT_WIDTH - macro_width()

func panel_height() -> int:
	return VIEWPORT_HEIGHT - HUD_HEIGHT
