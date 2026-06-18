extends RefCounted
class_name SpritePaths

const V2_ANT_DIR := "res://assets/sprites/v2/"
const V2_UI_DIR := "res://assets/sprites/ui/v2/"
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
	return "res://assets/%s_icon_32.png" % kind


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
