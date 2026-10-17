extends Node
## Versioned, validated local progress. No account or network dependency.
signal save_failed
const PATH = "user://progress.json"
const SCHEMA = 1
var data: Dictionary = {}
var last_error := ""

func _ready() -> void:
	load_progress()

func defaults() -> Dictionary:
	return {"schema_version": SCHEMA, "revision": 0, "levels": {}, "resume": {}, "settings": {"music": 0.55, "effects": 0.8, "vibration": true, "reduced_effects": false}, "tutorial_flags": {}}

func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	return value.get("schema_version") == SCHEMA and value.get("levels") is Dictionary and value.get("settings") is Dictionary and value.get("resume", {}) is Dictionary

func sanitize(value: Dictionary) -> Dictionary:
	var clean := defaults()
	clean.revision = bounded_int(value.get("revision", 0),0,2147483647)
	for key in value.levels:
		if str(key).is_valid_int() and int(key) >= 1 and int(key) <= 10 and value.levels[key] is Dictionary:
			var row: Dictionary = value.levels[key]
			clean.levels[str(key)] = {"completed": row.get("completed", false) == true, "stars": bounded_int(row.get("stars", 0),0,3), "fireflies": bounded_int(row.get("fireflies", 0),0,5)}
	for key in ["music", "effects"]:
		var number = value.settings.get(key, clean.settings[key])
		if (number is float or number is int) and is_finite(float(number)):
			clean.settings[key] = clampf(float(number), 0, 1)
	for key in ["vibration", "reduced_effects"]:
		clean.settings[key] = value.settings.get(key, clean.settings[key]) == true
	var resume: Dictionary = value.get("resume", {})
	var resume_level := bounded_int(resume.get("level", 0),0,11)
	if resume_level >= 1 and resume_level <= 10:
		var items: Array = []
		if resume.get("collected",[]) is Array:
			for id in resume.collected:
				if str(id) in ["0","1","2","3","4"] and not items.has(str(id)):
					items.append(str(id))
		var elapsed = resume.get("elapsed",0)
		elapsed = clampf(float(elapsed),0,1000000000) if (elapsed is int or elapsed is float) and is_finite(float(elapsed)) else 0.0
		clean.resume = {"level": resume_level, "checkpoint": resume.get("checkpoint",false) == true, "collected":items, "bridge":resume.get("bridge",false) == true, "receiver":resume.get("receiver",false) == true, "deaths":bounded_int(resume.get("deaths",0),0,1000000), "elapsed":elapsed}
	clean.tutorial_flags = value.get("tutorial_flags", {}) if value.get("tutorial_flags", {}) is Dictionary else {}
	return clean

func bounded_int(value: Variant, low: int, high: int) -> int:
	if (value is int or value is float) and is_finite(float(value)):
		return int(clampf(float(value),low,high))
	return low

func load_progress() -> void:
	data = defaults()
	for path in [PATH, PATH + ".bak", PATH + ".tmp"]:
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = read_json(file.get_as_text())
		if valid(parsed):
			data = sanitize(parsed)
			return
		# Retain unsupported or damaged files rather than overwriting the only copy.
		if path == PATH:
			DirAccess.copy_absolute(path, PATH + ".unreadable")

func write() -> bool:
	var next := data.duplicate(true)
	next.revision = int(data.revision) + 1
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return fail("Cannot open local storage")
	file.store_string(JSON.stringify(next))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return fail("Unable to write progress")
	var verification := FileAccess.open(PATH + ".tmp", FileAccess.READ)
	if verification == null or not valid(read_json(verification.get_as_text())):
		return fail("Progress verification failed")
	verification.close()
	if FileAccess.file_exists(PATH):
		error = DirAccess.copy_absolute(PATH, PATH + ".bak")
		if error != OK:
			return fail("Cannot retain progress backup")
	error = DirAccess.rename_absolute(PATH + ".tmp", PATH)
	if error != OK:
		return fail("Cannot commit progress")
	data.revision = next.revision
	last_error = ""
	return true

func read_json(text: String) -> Variant:
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

func fail(message: String) -> bool:
	last_error = message
	save_failed.emit()
	return false

func unlocked(level: int) -> bool:
	return level == 1 or data.levels.get(str(level - 1), {}).get("completed", false)

func best(level: int) -> Dictionary:
	return data.levels.get(str(level), {"completed": false, "stars": 0, "fireflies": 0})

func complete(level: int, fireflies: int, deaths: int) -> int:
	var stars := 1 + int(fireflies == 5) + int(fireflies == 5 and deaths == 0)
	var old := best(level)
	data.levels[str(level)] = {"completed": true, "stars": maxi(stars, int(old.stars)), "fireflies": maxi(fireflies, int(old.fireflies))}
	data.resume = {}
	write()
	return stars

func reset_progress() -> bool:
	var settings: Dictionary = data.settings.duplicate()
	data = defaults()
	data.settings = settings
	return write()

func set_setting(key: String, value: Variant) -> void:
	data.settings[key] = value
	write()

