class_name LanternLevels
extends RefCounted
## Authored layouts. Values are world coordinates; y is the walkable top.
const TITLES = ["A Light in the Woods", "The Hidden Crossing", "Firefly Hollow", "Beyond the Old Oak", "Echoes Below", "The Wandering Stones", "A Moth in the Dark", "The Sunken Courtyard", "The Last Beacon", "Home of the Fireflies"]
const LAYOUTS = [
	[[0,530,500],[610,530,390],[1140,500,380],[1640,530,420],[2190,510,500]],
	[[0,540,420],[530,490,350],[1020,520,400],[1540,470,350],[2010,510,460],[2600,500,400]],
	[[0,540,420],[540,475,300],[980,510,390],[1490,460,350],[1960,510,370],[2450,480,510]],
	[[0,530,450],[560,460,330],[1030,500,360],[1510,440,350],[1980,500,410],[2510,470,500]],
	[[0,540,430],[540,480,350],[1030,530,360],[1510,470,350],[1980,520,400],[2500,490,510]],
	[[0,540,440],[550,490,330],[1020,530,380],[1520,470,330],[1970,510,390],[2480,480,510]],
	[[0,540,420],[530,470,340],[1010,510,380],[1510,450,350],[1980,500,400],[2500,470,520]],
	[[0,540,440],[550,480,330],[1020,520,380],[1520,460,350],[1990,510,420],[2530,480,520]],
	[[0,540,420],[530,470,350],[1020,510,380],[1520,440,350],[1990,500,420],[2530,470,550]],
	[[0,540,440],[550,470,330],[1020,520,380],[1520,450,350],[1990,510,420],[2530,470,600]]
]

static func get_level(index: int) -> Dictionary:
	index = clampi(index, 1, 10)
	var source: Array = LAYOUTS[index - 1]
	var platforms: Array[Rect2] = []
	for row in source:
		platforms.append(Rect2(row[0], row[1], row[2], 130))
	var theme := 0 if index <= 4 else (1 if index <= 7 else 2)
	var a: Rect2 = platforms[1]
	var b: Rect2 = platforms[2]
	var bridge := Rect2(a.end.x - 2, a.position.y, b.position.x - a.end.x + 4, 18)
	var last: Rect2 = platforms[-1]
	var receiver_platform: Rect2 = platforms[-2]
	var fireflies: Array[Vector2] = []
	for i in range(5):
		var platform: Rect2 = platforms[mini(i, platforms.size() - 1)]
		fireflies.append(Vector2(platform.position.x + platform.size.x * (0.48 if i % 2 == 0 else 0.7), platform.position.y - (68 if i != 3 else 106)))
	return {"id": index, "title": TITLES[index - 1], "theme": theme, "platforms": platforms, "bridge": bridge, "spawn": Vector2(145, platforms[0].position.y - 2), "checkpoint": Vector2(b.position.x + 160, b.position.y), "receiver": Vector2(receiver_platform.end.x - 100, receiver_platform.position.y), "exit": Vector2(last.end.x - 150, last.position.y), "width": last.end.x + 40, "fireflies": fireflies, "enemy": Vector2(platforms[3].position.x + 150, platforms[3].position.y - 25) if index >= 3 else Vector2(-1000,-1000), "moving": index in [6,8,9,10]}

static func validate() -> Array[String]:
	var errors: Array[String] = []
	for index in range(1, 11):
		var level := get_level(index)
		if level.fireflies.size() != 5:
			errors.append("Level %d must contain five fireflies" % index)
		var platforms: Array = level.platforms
		for i in range(1, platforms.size()):
			var previous: Rect2 = platforms[i - 1]
			var current: Rect2 = platforms[i]
			if current.position.x - previous.end.x > 150:
				errors.append("Level %d gap exceeds jump budget" % index)
			if previous.position.y - current.position.y > 90:
				errors.append("Level %d rise exceeds jump budget" % index)
	return errors

