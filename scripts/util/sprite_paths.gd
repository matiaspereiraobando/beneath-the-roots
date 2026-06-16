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
