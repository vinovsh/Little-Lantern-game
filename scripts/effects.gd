class_name LanternEffects
extends Node2D
var particles: Array[Dictionary] = []
var ambient := true
var time := 0.0
var extent := 3600.0
var seed_points: Array[Vector2] = []
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 48913
	for i in range(55):
		seed_points.append(Vector2(random.randf_range(0,extent), random.randf_range(90,570)))

func burst(point: Vector2, color: Color, count := 16, power := 90.0) -> void:
	if Save.data.settings.reduced_effects:
		count = mini(count, 5)
	for i in range(count):
		var velocity := Vector2.from_angle(random.randf_range(-PI,PI)) * random.randf_range(power * .3,power)
		particles.append({"p": point, "v": velocity, "life": random.randf_range(.35,.9), "max": 1.0, "color": color, "r": random.randf_range(1.5,4.0)})

func _process(delta: float) -> void:
	time += delta
	for i in range(particles.size()-1,-1,-1):
		var part: Dictionary = particles[i]
		part.life -= delta
		part.p += part.v * delta
		part.v.y += 42 * delta
		if part.life <= 0:
			particles.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if ambient and not Save.data.settings.reduced_effects:
		for i in range(seed_points.size()):
			var base: Vector2 = seed_points[i]
			var point := base + Vector2(sin(time * .45 + i) * 24, cos(time * .65 + i * 2) * 13)
			var a := .25 + .4 * absf(sin(time + i))
			glow(point, Color(1,.72,.25,a), 2)
	for part in particles:
		var col: Color = part.color
		col.a *= clampf(part.life * 1.6,0,1)
		glow(part.p,col,part.r)

func glow(point: Vector2, color: Color, radius: float) -> void:
	var haze := color
	haze.a *= .08
	draw_circle(point, radius * 5,haze)
	haze.a *= 2
	draw_circle(point,radius * 2.5,haze)
	draw_circle(point,radius,color)
