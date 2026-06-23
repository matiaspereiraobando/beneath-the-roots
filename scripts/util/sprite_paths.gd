extends RefCounted
class_name SpritePaths

const V2_ANT_DIR := "res://assets/sprites/v2/"
const V2_UI_DIR := "res://assets/sprites/ui/v2/"
const HUD_ICON_DIR := "res://assets/sprites/ui/hud/"
const LEGACY_ANT_DIR := "res://assets/sprites/"
const LEGACY_UI_DIR := "res://assets/sprites/ui/"


static func ant_sprite(name: String) -> String:
	var v2 := V2_ANT_DIR + name + ".png"
	if ResourceLoader.exists(v2):
		return v2
	return LEGACY_ANT_DIR + name + ".png"


static func ant_walk(name: String) -> String:
	var v2 := V2_ANT_DIR + "ants/" + name + "_walk.png"
	if ResourceLoader.exists(v2):
		return v2
	return "res://assets/sprites/ants/" + name + "_walk.png"


static func ui_icon(name: String) -> String:
	var v2 := V2_UI_DIR + name + ".png"
	if ResourceLoader.exists(v2):
		return v2
	return LEGACY_UI_DIR + name + ".png"


static func hud_icon(kind: String) -> String:
	return HUD_ICON_DIR + "%s_icon_32.png" % kind


static func hud_icon_anim_sheet(kind: String) -> String:
	return HUD_ICON_DIR + "%s_icon_32_anim_sheet.png" % kind


static func hud_icon_anim_meta(kind: String) -> String:
	return HUD_ICON_DIR + "%s_icon_32_anim.meta.txt" % kind


static func colony_drawer_bg() -> String:
	return "res://assets/sprites/ui/colony/colony_drawer_bg_365.png"


static func action_tool_sheet(kind: String) -> String:
	return "res://assets/sprites/ui/actions/actions_%s_56.png" % kind


static func structure_tool_sheet(kind: String) -> String:
	return "res://assets/sprites/ui/actions/structure_button_%s_56.png" % kind


static func macro_sky_background() -> String:
	return "res://assets/sprites/macro/top_bg_02_1280_96.png"


static func enemy_walk_sheet(enemy_type: String) -> String:
	return "res://assets/sprites/enemies/%s/walk_sheet.png" % enemy_type


static func enemy_static(enemy_type: String) -> String:
	return "res://assets/sprites/enemies/%s/static.png" % enemy_type


static func spitter_projectile_sheet() -> String:
	return "res://assets/sprites/projectiles/spitter_sheet.png"


static func spitter_splat_sheet() -> String:
	return "res://assets/sprites/projectiles/spitter_splat_sheet.png"


static func micro_background() -> String:
	var v2 := "res://assets/micro/nursery_background_v2.png"
	if ResourceLoader.exists(v2):
		return v2
	return "res://assets/micro/nursery_background.png"


static func micro_ant_sprite(ant_type: int) -> String:
	const AntTypes = preload("res://scripts/data/ant_types.gd")
	var names := {
		AntTypes.Type.GATHERER: "gatherer_side",
		AntTypes.Type.BUILDER: "builder_side",
		AntTypes.Type.SOLDIER: "soldier_side",
	}
	var base: String = names.get(ant_type, "gatherer_side")
	var path := V2_ANT_DIR + "side/" + base + ".png"
	if ResourceLoader.exists(path):
		return path
	return ""


static func micro_queen_sprite() -> String:
	var path := V2_ANT_DIR + "side/queen_side.png"
	if ResourceLoader.exists(path):
		return path
	return ""
