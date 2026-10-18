class_name LanternWorld
extends Node2D
signal status_changed
signal died
signal finished(fireflies: int, deaths: int)
signal checkpoint_saved
signal message_requested(text: String)
const GOLD = Color(1.0,0.76,0.31)
const PLATFORM = preload("res://assets/art/platform.png")
const GATE = preload("res://assets/art/gate.png")
const RECEIVER = preload("res://assets/art/receiver.png")
const CHECKPOINT = preload("res://assets/art/checkpoint.png")
var level: Dictionary
var hero: LanternHero
var camera: Camera2D
var effects: LanternEffects
var collected: Dictionary = {}
var bridge_on := false
var receiver_on := false
var checkpoint_on := false
var checkpoint_snapshot: Dictionary = {}
var bridge_body: StaticBody2D
var moving_body: AnimatableBody2D
var moving_base := Vector2.ZERO
var enemy_position := Vector2.ZERO
var safe_position := Vector2.ZERO
var charge := 0.0
var elapsed := 0.0
var deaths := 0
var is_dead := false
var is_finished := false
var revived := false
var hint_time := 0.0
var effect_clock := 0.0
var time := 0.0
var checkpoint_flash := 0.0
var attempt_token := ""

func setup(index: int, resume: Dictionary = {}) -> void:
	level = LanternLevels.get_level(index)
	attempt_token = str(Time.get_ticks_usec()) + "-" + str(index)
	for platform in level.platforms:
		add_body(platform)
	bridge_body = add_body(level.bridge)
	bridge_body.collision_layer = 0
	if level.moving:
		moving_base = Vector2(level.platforms[3].position.x + 130, level.platforms[3].position.y - 65)
		moving_body = AnimatableBody2D.new()
		moving_body.position = moving_base
		moving_body.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(105,18)
		shape.shape = rect
		shape.position = Vector2(52.5,9)
		moving_body.add_child(shape)
		add_child(moving_body)
	hero = LanternHero.new()
	hero.position = level.spawn
	add_child(hero)
	hero.jumped.connect(func(): Audio.cue("jump"); effects.burst(hero.position,Color(.65,.82,.72,.5),7,45))
	hero.landed.connect(func(): effects.burst(hero.position,Color(.7,.8,.7,.55),8,45))
	effects = LanternEffects.new()
	effects.extent = level.width
	effects.z_index = 8
	add_child(effects)
	camera = Camera2D.new()
	camera.position = Vector2(640,360)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6
	add_child(camera)
	enemy_position = level.enemy
	safe_position = level.spawn
	checkpoint_snapshot = snapshot()
	if not resume.is_empty() and int(resume.get("level", 0)) == index:
		apply_snapshot(resume)
		checkpoint_on = resume.get("checkpoint", false) == true
		deaths = maxi(0,int(resume.get("deaths",0)))
		elapsed = maxf(0,float(resume.get("elapsed",0)))
		checkpoint_snapshot = snapshot()
		hero.position = level.checkpoint + Vector2(0,-2) if checkpoint_on else level.spawn
		safe_position = hero.position

func add_body(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var geometry := RectangleShape2D.new()
	geometry.size = Vector2(rect.size.x,28)
	shape.shape = geometry
	shape.position = Vector2(rect.size.x / 2,14)
	body.add_child(shape)
	add_child(body)
	return body

func _physics_process(delta: float) -> void:
	if hero == null:
		return
	time += delta
	hint_time = maxf(0,hint_time - delta)
	checkpoint_flash = maxf(0,checkpoint_flash - delta)
	var viewport_width := get_viewport_rect().size.x
	camera.position = Vector2(clampf(hero.position.x + 215, viewport_width / 2, maxf(viewport_width / 2,level.width - viewport_width / 2)), 360)
	if is_dead or is_finished:
		if is_finished and not Save.data.settings.reduced_effects:
			hero.sprite.position.y = -64 - absf(sin(time * 6)) * 7
		queue_redraw()
		return
	elapsed += delta
	if moving_body != null:
		moving_body.position = moving_base + Vector2(sin(time * .85) * 35, sin(time * 1.1) * 20)
	if hero.is_on_floor() and hero.position.y < 650:
		safe_position = hero.position
	if hero.position.y > 760:
		die()
		return
	if hero.lantern_on:
		if not bridge_on and can_illuminate(level.bridge.get_center() - Vector2(0,30), 340):
			bridge_on = true
			bridge_body.collision_layer = 1
			effects.burst(level.bridge.get_center(),GOLD,32,115)
			Audio.cue("magic")
			message_requested.emit("A hidden path awakens")
		if not receiver_on and can_illuminate(level.receiver - Vector2(0,60), 290):
			charge += delta
			if charge >= .5:
				receiver_on = true
				effects.burst(level.receiver - Vector2(0,60),GOLD,38,120)
				Audio.cue("gate")
				message_requested.emit("The ancient gate is open")
		else:
			charge = maxf(0,charge - delta * .5)
	else:
		charge = maxf(0,charge - delta * .5)
	for i in range(level.fireflies.size()):
		if not collected.has(str(i)) and hero.position.distance_to(level.fireflies[i] + Vector2(0,35)) < 65:
			collected[str(i)] = true
			effects.burst(level.fireflies[i],GOLD,20,95)
			Audio.cue("pickup",1 + collected.size() * .06)
			status_changed.emit()
	if not checkpoint_on and hero.position.distance_to(level.checkpoint) < 55:
		checkpoint_on = true
		checkpoint_flash = 2
		checkpoint_snapshot = snapshot()
		persist_checkpoint()
		effects.burst(level.checkpoint - Vector2(0,35),Color(.4,1,.82),30,110)
		Audio.cue("checkpoint")
		checkpoint_saved.emit()
	if level.id >= 3:
		var patrol: Vector2 = level.enemy
		var target_x: float = patrol.x + sin(time * .75) * 85
		if hero.lantern_on and absf(hero.position.x - enemy_position.x) < 260:
			target_x = clampf(hero.position.x, level.platforms[3].position.x + 35, level.platforms[3].end.x - 35)
		enemy_position.x = move_toward(enemy_position.x,target_x,45 * delta)
		enemy_position.y = patrol.y + sin(time * 3) * 9
		if hero.protection <= 0 and (hero.position - Vector2(0,31)).distance_to(enemy_position) < 33:
			die()
	if hero.position.distance_to(level.exit) < 50:
		if receiver_on:
			is_finished = true
			hero.frozen = true
			hero.sprite.play("celebrate")
			effects.burst(hero.position - Vector2(0,60),GOLD,65,230)
			Audio.cue("complete")
			finished.emit(collected.size(),deaths)
		elif int(time * 10) % 20 == 0:
			message_requested.emit("Shine your lantern on the sun receiver")
	effect_clock += delta
	if hero.lantern_on and effect_clock > .12 and not Save.data.settings.reduced_effects:
		effect_clock = 0
		effects.burst(hero.position + Vector2(hero.facing * 26,-30),GOLD * Color(1,1,1,.45),1,20)
	queue_redraw()

func can_illuminate(target: Vector2, radius: float) -> bool:
	var origin := hero.position + Vector2(hero.facing * 20,-42)
	var offset := target - origin
	if offset.length() > radius or offset.x * hero.facing < -25 or absf(offset.y) > 140:
		return false
	var query := PhysicsRayQueryParameters2D.create(origin,target,1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func snapshot() -> Dictionary:
	return {"level": level.id, "checkpoint": checkpoint_on, "collected": collected.keys(), "bridge": bridge_on, "receiver": receiver_on, "deaths": deaths, "elapsed": elapsed}

func persist_checkpoint() -> void:
	if is_finished:
		return
	var saved := checkpoint_snapshot.duplicate(true)
	saved.deaths = deaths
	saved.elapsed = elapsed
	Save.data.resume = saved
	Save.write()

func apply_snapshot(saved: Dictionary) -> void:
	collected.clear()
	var items = saved.get("collected", [])
	if items is Array:
		for key in items:
			if str(key) in ["0","1","2","3","4"]:
				collected[str(key)] = true
	bridge_on = saved.get("bridge",false) == true
	receiver_on = saved.get("receiver",false) == true
	bridge_body.collision_layer = 1 if bridge_on else 0
	charge = .5 if receiver_on else 0

func retry() -> void:
	apply_snapshot(checkpoint_snapshot)
	hero.reset_at(level.checkpoint + Vector2(0,-2) if checkpoint_on else level.spawn)
	is_dead = false
	enemy_position = level.enemy
	status_changed.emit()

func revive() -> void:
	if revived or not is_dead:
		return
	revived = true
	hero.reset_at(safe_position + Vector2(0,-3))
	hero.protection = 2
	is_dead = false
	effects.burst(hero.position - Vector2(0,40),GOLD,35,90)

func die() -> void:
	if is_dead or is_finished:
		return
	is_dead = true
	deaths += 1
	hero.frozen = true
	persist_checkpoint()
	Audio.cue("hurt")
	if Save.data.settings.vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(45)
	effects.burst(hero.position - Vector2(0,30),Color(.8,.68,1),24,130)
	died.emit()

func show_hint() -> void:
	hint_time = 8
	message_requested.emit("Look for the glowing bridge" if not bridge_on else "Follow the light to the sun receiver")

func _draw() -> void:
	if level.is_empty():
		return
	for rect in level.platforms:
		draw_platform(rect)
	if moving_body != null:
		draw_platform(Rect2(moving_body.position,Vector2(105,75)))
	draw_bridge()
	var exit_point: Vector2 = level.exit
	if receiver_on:
		draw_circle(exit_point - Vector2(0,105),115,Color(1,.65,.15,.035))
		draw_circle(exit_point - Vector2(0,105),85,Color(1,.65,.15,.07))
		draw_arc(exit_point - Vector2(0,105),56,PI,TAU,36,GOLD,4,true)
		draw_rect(Rect2(exit_point + Vector2(-54,-108),Vector2(108,106)),Color(1,.72,.22,.13))
	draw_texture_rect(GATE,Rect2(exit_point - Vector2(105,258),Vector2(210,258)),false,Color(1,1,1,.48 if receiver_on else 1))
	var sun: Vector2 = level.receiver
	draw_texture_rect(RECEIVER,Rect2(sun - Vector2(48,105),Vector2(96,105)),false)
	if receiver_on or charge > 0:
		draw_arc(sun - Vector2(0,66),23,-PI/2,-PI/2 + TAU * minf(1,charge * 2),30,GOLD,3,true)
		if receiver_on:
			draw_line(sun - Vector2(0,64),exit_point - Vector2(0,105),Color(1,.73,.2,.14),7,true)
			draw_line(sun - Vector2(0,64),exit_point - Vector2(0,105),Color(1,.83,.4,.6),1.5,true)
	var cp: Vector2 = level.checkpoint
	draw_texture_rect(CHECKPOINT,Rect2(cp - Vector2(34,89),Vector2(68,89)),false,Color(1,1,1,1 if checkpoint_on else .65))
	if checkpoint_on:
		draw_circle(cp - Vector2(0,48),38,Color(.25,1,.75,.08 + checkpoint_flash * .03))
	for i in range(level.fireflies.size()):
		if not collected.has(str(i)):
			draw_firefly(level.fireflies[i] + Vector2(0,sin(time * 2.4 + i) * 7),i)
	if level.id >= 3:
		draw_enemy()
	if hero != null and hero.lantern_on:
		var origin := hero.position + Vector2(hero.facing * 27,-35)
		for i in range(12,0,-1):
			draw_circle(origin,float(i) * 9,Color(1,.68,.2,.0035 * (13-i)))
		var points := PackedVector2Array([origin,origin + Vector2(hero.facing * 260,-105),origin + Vector2(hero.facing * 280,75)])
		draw_colored_polygon(points,Color(1,.79,.35,.055))
	if hint_time > 0:
		var point: Vector2 = level.bridge.get_center() if not bridge_on else level.receiver - Vector2(0,115)
		draw_arc(point,36 + sin(time * 4) * 4,0,TAU,32,Color(1,.88,.4,.8),3,true)
		var tip := point - Vector2(0,53 + sin(time * 4) * 5)
		draw_colored_polygon(PackedVector2Array([tip,tip + Vector2(-10,-15),tip + Vector2(10,-15)]),GOLD)

func draw_platform(rect: Rect2) -> void:
	var chunks := maxi(1,int(ceil(rect.size.x / 310)))
	for i in range(chunks):
		var width := rect.size.x / chunks
		draw_texture_rect(PLATFORM,Rect2(rect.position + Vector2(i * width - 5,-46),Vector2(width + 10,rect.size.y + 35)),false)

func draw_bridge() -> void:
	var rect: Rect2 = level.bridge
	var color := Color(1,.8,.35,.85 if bridge_on else .17)
	draw_line(rect.position,Vector2(rect.end.x,rect.position.y),color,3,true)
	for i in range(int(rect.size.x / 24) + 1):
		var x: float = rect.position.x + i * 24
		draw_rect(Rect2(x,rect.position.y,22,14),Color(1,.7,.22,.18 if bridge_on else .025))
		if bridge_on:
			draw_rect(Rect2(x,rect.position.y,22,14),color,false,1.0)

func draw_firefly(point: Vector2, index: int) -> void:
	draw_circle(point,20,Color(1,.72,.2,.055))
	draw_circle(point,10,Color(1,.78,.3,.14))
	var wing := sin(time * 14 + index) * 3
	draw_circle(point + Vector2(-5,-3),3 + wing *.3,Color(1,.93,.65,.7))
	draw_circle(point + Vector2(5,-3),3 - wing *.3,Color(1,.93,.65,.7))
	draw_circle(point,3.5,Color(1,.9,.48))
	draw_line(point - Vector2(0,9),point + Vector2(0,9),Color(1,.83,.44,.55),1,true)
	draw_line(point - Vector2(9,0),point + Vector2(9,0),Color(1,.83,.44,.55),1,true)

func draw_enemy() -> void:
	var flutter := sin(time * 20) * 8
	draw_circle(enemy_position,30,Color(.7,.4,1,.05))
	draw_set_transform(enemy_position)
	draw_ellipse(Vector2(-11,0),Vector2(18,8 + absf(flutter)),Color(.5,.42,.72,.9))
	draw_ellipse(Vector2(11,0),Vector2(18,8 + absf(flutter)),Color(.5,.42,.72,.9))
	draw_circle(Vector2.ZERO,9,Color(.13,.13,.25))
	draw_circle(Vector2(-3,-2),2,Color(1,.63,.65))
	draw_circle(Vector2(3,-2),2,Color(1,.63,.65))
	draw_set_transform(Vector2.ZERO)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		points.append(center + Vector2(cos(i * TAU / 20.0),sin(i * TAU / 20.0)) * radius)
	draw_colored_polygon(points,color)
