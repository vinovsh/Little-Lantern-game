class_name LanternLevels
extends RefCounted
const COUNT = 40
const CHAPTERS = ["Whispering Woods","The Reversed River","The Ember Mountain","The Windglass Highlands"]
static var catalog: Array = []
static func all() -> Array:
	if catalog.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/campaign.json"))
		if parsed is Array:catalog = parsed
	return catalog
static func get_level(index: int) -> Dictionary:
	var value: Dictionary = all()[clampi(index,1,COUNT)-1].duplicate(true)
	for key in ["spawn","exit","secret"]:value[key] = Vector2(value[key][0],value[key][1])
	return value
static func title(index: int) -> String:
	return str(all()[clampi(index,1,COUNT)-1].title)
static func validate() -> Array[String]:
	var errors: Array[String] = []
	if all().size()!=COUNT:errors.append("Campaign must contain forty levels")
	var layouts = {}
	for row in all():
		var signature = JSON.stringify(row.platforms)
		if layouts.has(signature):errors.append("Repeated layout: "+str(row.id))
		layouts[signature] = true
		if row.fireflies.size()!=5 or row.requires.is_empty():errors.append("Missing objective or collectibles: "+str(row.id))
		var ids = {}
		for item in row.objects:
			if ids.has(item.id):errors.append("Duplicate object: "+str(item.id))
			ids[item.id] = true
	return errors
