extends Node
## Versioned, validated local progress. No account or network dependency.
signal save_failed
const PATH = "user://progress.json"
const SCHEMA = 2
var data: Dictionary = {}
var last_error := ""

func _ready() -> void:
	load_progress()

func defaults() -> Dictionary:
	return {"schema_version":SCHEMA,"campaign_revision":2,"revision":0,"legacy_unlocked":1,"classic":{},"levels":{},"resume":{},"settings":{"music":.55,"effects":.8,"vibration":true,"reduced_effects":false},"tutorial_flags":{}}

func valid(value: Variant) -> bool:
	return value is Dictionary and (value.get("schema_version")==1 or value.get("schema_version")==2) and value.get("levels") is Dictionary and value.get("settings") is Dictionary and value.get("resume",{}) is Dictionary

func sanitize(value: Dictionary) -> Dictionary:
	var clean = defaults()
	clean.revision = bounded_int(value.get("revision",0),0,2147483647)
	for key in ["music","effects"]:
		var number = value.settings.get(key,clean.settings[key])
		if (number is int or number is float) and is_finite(float(number)):clean.settings[key] = clampf(float(number),0,1)
	for key in ["vibration","reduced_effects"]:clean.settings[key] = value.settings.get(key,clean.settings[key])==true
	if int(value.get("schema_version",1))==1:
		for key in value.levels:
			if str(key).is_valid_int() and int(key)>=1 and int(key)<=10 and value.levels[key] is Dictionary:
				clean.classic[str(key)] = value.levels[key].duplicate()
				if value.levels[key].get("completed",false)==true:clean.legacy_unlocked = maxi(int(clean.legacy_unlocked),mini(10,int(key)+1))
		return clean
	clean.legacy_unlocked = bounded_int(value.get("legacy_unlocked",1),1,10)
	if value.get("classic") is Dictionary:clean.classic = value.classic.duplicate(true)
	for key in value.levels:
		if str(key).is_valid_int() and int(key)>=1 and int(key)<=40 and value.levels[key] is Dictionary:
			var row: Dictionary = value.levels[key]
			clean.levels[str(key)] = {"completed":row.get("completed",false)==true,"stars":bounded_int(row.get("stars",0),0,3),"fireflies":bounded_int(row.get("fireflies",0),0,5),"secret":row.get("secret",false)==true}
	var resume: Dictionary = value.get("resume",{})
	var index = bounded_int(resume.get("level",0),0,41)
	if index>=1 and index<=40:
		var definition = LanternLevels.get_level(index)
		var known = {}
		for o in definition.objects:known[str(o.id)] = true
		for rule in definition.rules:known[str(rule.sets)] = true
		for uid in definition.get("state_flags",[]):known[str(uid)] = true
		var flags = {}
		var values = {}
		var crates = {}
		if resume.get("flags") is Dictionary:
			for key in resume.flags:
				if known.has(str(key)):flags[str(key)] = resume.flags[key]==true
		if resume.get("values") is Dictionary:
			for key in resume.values:
				if known.has(str(key)):values[str(key)] = bounded_int(resume.values[key],0,3)
		if resume.get("crates") is Dictionary:
			for key in resume.crates:
				var position = resume.crates[key]
				if known.has(str(key)) and position is Array and position.size()==2 and (position[0] is float or position[0] is int) and (position[1] is float or position[1] is int) and is_finite(float(position[0])) and is_finite(float(position[1])):
					crates[str(key)] = [clampf(float(position[0]),0,float(definition.width)),clampf(float(position[1]),0,float(definition.height))]
		var items = []
		if resume.get("collected") is Array:
			for key in resume.collected:
				if str(key) in ["0","1","2","3","4"] and not items.has(str(key)):items.append(str(key))
		var elapsed = resume.get("elapsed",0)
		elapsed = clampf(float(elapsed),0,1000000000) if (elapsed is int or elapsed is float) and is_finite(float(elapsed)) else 0.0
		clean.resume = {"level":index,"checkpoint_id":bounded_int(resume.get("checkpoint_id",0),0,definition.checkpoints.size()-1),"flags":flags,"values":values,"crates":crates,"collected":items,"lens":bounded_int(resume.get("lens",0),0,2),"receiver":resume.get("receiver",false)==true,"secret":resume.get("secret",false)==true,"clue":resume.get("clue",false)==true,"elapsed":elapsed,"deaths":bounded_int(resume.get("deaths",0),0,1000000)}
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
			if int(parsed.schema_version)==1:write()
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
	if level<1 or level>40:return false
	return level==1 or (level<=10 and level<=int(data.get("legacy_unlocked",1))) or data.levels.get(str(level-1),{}).get("completed",false)

func best(level: int) -> Dictionary:
	return data.levels.get(str(level),{"completed":false,"stars":0,"fireflies":0,"secret":false})

func complete(level: int, fireflies: int, _deaths: int, discovery = false) -> int:
	if level<1 or level>40:return 0
	var old = best(level)
	var flies = maxi(fireflies,int(old.fireflies))
	var discovered = discovery or old.get("secret",false)
	var stars = 1+int(flies==5)+int(discovered)
	data.levels[str(level)] = {"completed":true,"stars":maxi(stars,int(old.stars)),"fireflies":flies,"secret":discovered}
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

