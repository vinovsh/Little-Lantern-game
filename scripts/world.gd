class_name LanternWorld
extends Node2D
signal status_changed
signal died
signal finished(fireflies: int, deaths: int)
signal checkpoint_saved
signal message_requested(text: String)
const GOLD = Color(1,.79,.36)
const PLATFORM = preload("res://assets/art/platform.png")
const GATE = preload("res://assets/art/gate.png")
const RECEIVER = preload("res://assets/art/receiver.png")
const CHECKPOINT = preload("res://assets/art/checkpoint.png")
const HERO_ART = preload("res://assets/art/hero.png")
const FONT = preload("res://assets/fonts/Interface.ttf")
var level: Dictionary
var hero: LanternHero
var camera: Camera2D
var effects: LanternEffects
var collected: Dictionary = {}
var flags: Dictionary = {}
var values: Dictionary = {}
var charges: Dictionary = {}
var objects: Dictionary = {}
var crates: Dictionary = {}
var mobs: Array[LanternEnemy] = []
var platforms: Array[Dictionary] = []
var vehicles: Array[Dictionary] = []
var temporary: Dictionary = {}
var brittle: Dictionary = {}
var checkpoint_on = false
var checkpoint_id = 0
var checkpoint_snapshot: Dictionary = {}
var receiver_on = false
var bridge_on = false
var is_dead = false
var is_finished = false
var revived = false
var secret_found = false
var clue_read = false
var health = 3
var deaths = 0
var elapsed = 0.0
var time = 0.0
var safe_position = Vector2.ZERO
var attempt_token = ""
var hint_time = 0.0
var hint_step = 0
var lens = 0
var context_id = ""
var grabbed_crate = ""
var gate_body: StaticBody2D
var last_notice = 0.0
var auto_hint_shown = false

func point(data) -> Vector2:
	return Vector2(float(data[0]),float(data[1]))

func setup(index: int, resume: Dictionary = {}) -> void:
	level = LanternLevels.get_level(index)
	attempt_token = str(Time.get_ticks_usec())+"-"+str(index)
	lens = 1 if index>=21 else 0
	for row in level.platforms:
		var body = add_body(Rect2(row.x,row.y,row.w,28))
		platforms.append({"data":row,"body":body})
	for data in level.objects:
		objects[str(data.id)] = data
		values[str(data.id)] = int(data.get("initial",0))
		if data.kind=="crate":
			var crate = LanternCrate.new()
			crate.position = point(data.pos)
			crate.home = crate.position
			add_child(crate)
			crates[str(data.id)] = crate
		elif data.kind=="ice":
			var body = add_body(Rect2(point(data.pos)+Vector2(-95,-10),Vector2(190,22)))
			body.collision_layer = 0
			data["ice_body"] = body
	for data in level.vehicles:
		var body = AnimatableBody2D.new()
		body.collision_layer = 1
		body.position = point(data.nodes[0])
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(190,22)
		shape.shape = rect
		shape.position.y = 11
		shape.one_way_collision = true
		body.add_child(shape)
		add_child(body)
		vehicles.append({"data":data,"body":body,"stop":0,"direction":1,"wait":2.0})
	for data in level.enemies:
		var enemy = LanternEnemy.new()
		enemy.configure(data,self)
		add_child(enemy)
		mobs.append(enemy)
	gate_body = add_body(Rect2(level.exit+Vector2(-70,-140),Vector2(24,140)),false)
	hero = LanternHero.new()
	hero.position = level.spawn
	add_child(hero)
	hero.glider_unlocked = index>=31
	hero.jumped.connect(func(): Audio.cue("jump"))
	hero.landed.connect(func(): effects.burst(hero.position,Color(.7,.8,.7,.5),6,45))
	effects = LanternEffects.new()
	effects.extent = level.width
	effects.z_index = 8
	add_child(effects)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7
	add_child(camera)
	safe_position = hero.position
	if not resume.is_empty() and int(resume.get("level",0))==index:
		apply_snapshot(resume)
		hero.reset_at(point(level.checkpoints[checkpoint_id]))
	update_camera(true)
	checkpoint_snapshot = snapshot()
	update_solids()

func add_body(rect: Rect2, one_way = true) -> StaticBody2D:
	var body = StaticBody2D.new()
	body.position = rect.position
	body.collision_layer = 1
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.size/2
	collision.one_way_collision = one_way
	body.add_child(collision)
	add_child(body)
	return body

func meets(requirements: Array) -> bool:
	for requirement in requirements:
		var text = str(requirement)
		if text.begins_with("!"):
			if flags.get(text.substr(1),false):return false
		elif text.contains(":"):
			var pair = text.split(":")
			if int(values.get(pair[0],0))!=int(pair[1]):return false
		elif not bool(flags.get(text,false)):return false
	return true

func mark(uid: String) -> void:
	if bool(flags.get(uid,false)):return
	flags[uid] = true
	last_notice = elapsed
	if uid in ["phase1","phase2","phase3"]:
		for enemy in mobs:enemy.reset_pose()
		health = 3
		hero.protection = 2
		message_requested.emit("Beacon phase restored · progress saved")
		effects.burst(hero.position-Vector2(0,40),GOLD,35,120)
	Audio.cue("magic")
	persist_checkpoint()
	status_changed.emit()

func _physics_process(delta: float) -> void:
	if hero==null:return
	time += delta
	hint_time = maxf(0,hint_time-delta)
	update_camera()
	if is_dead or is_finished:
		queue_redraw()
		return
	elapsed += delta
	if hero.position.y>float(level.height)+120:
		die()
		return
	hero.wet = false
	hero.wind = Vector2.ZERO
	hero.on_ice = false
	hero.pushing = false
	for row in platforms:
		var r = row.data
		if str(r.get("material",""))=="ice" and absf(hero.position.y-float(r.y))<12 and hero.position.x>float(r.x) and hero.position.x<float(r.x)+float(r.w):hero.on_ice = true
	for z in level.zones:process_zone(z,delta)
	for vehicle in vehicles:step_vehicle(vehicle,delta)
	if not Input.is_action_pressed("interact"):grabbed_crate = ""
	context_id = grabbed_crate if not grabbed_crate.is_empty() else nearest_object()
	if Input.is_action_just_pressed("interact"):interact(context_id)
	for uid in crates:
		var crate: LanternCrate = crates[uid]
		var data: Dictionary = objects[uid]
		var direction = 0.0
		if not bool(flags.get(uid,false)) and grabbed_crate==uid and Input.is_action_pressed("interact"):
			direction = hero.touch_direction+Input.get_axis("left","right")
			hero.pushing = true
		var surface = INF
		if data.get("buoyant",false):surface = surface_at(crate.position)
		if not bool(flags.get(uid,false)):crate.step(delta,direction,surface)
		if crate.position.y>float(level.height)+50:crate.position = crate.home
		if meets(data.get("when",[])) and crate.position.distance_to(point(data.target))<28:mark(uid)
	if hero.pushing:hero.wind *= .15
	for uid in objects:step_object(objects[uid],delta)
	for rule in level.rules:
		if meets(rule.needs):mark(str(rule.sets))
	for uid in temporary.keys():
		var data: Dictionary = objects[uid]
		var occupied = absf(hero.position.x-point(data.pos).x)<110 and absf(hero.position.y-(point(data.pos).y-10))<18
		if not occupied:temporary[uid] = float(temporary[uid])-delta
		if float(temporary[uid])<=0:
			temporary.erase(uid)
			flags.erase(uid)
	var active: Array = []
	for enemy in mobs:
		if enemy.position.distance_to(hero.position)<(1250 if enemy.boss else 720) and enemy_visible(enemy):active.append(enemy)
	active.sort_custom(func(a,b):return a.position.distance_squared_to(hero.position)<b.position.distance_squared_to(hero.position))
	for enemy in mobs:
		var rank = active.find(enemy)
		enemy.tick(delta,rank>=0 and rank<3)
	for i in range(5):
		if not collected.has(str(i)) and hero.position.distance_to(point(level.fireflies[i])+Vector2(0,30))<58:
			collected[str(i)] = true
			effects.burst(point(level.fireflies[i]),GOLD,20,90)
			Audio.cue("pickup")
			persist_checkpoint()
			status_changed.emit()
	if not secret_found and hero.position.distance_to(level.secret)<55:
		secret_found = true
		effects.burst(level.secret-Vector2(0,35),Color(.55,.9,1),32,110)
		message_requested.emit("Memory found · "+str(level.discovery))
		persist_checkpoint()
	for i in range(1,level.checkpoints.size()):
		if checkpoint_id<i and hero.position.distance_to(point(level.checkpoints[i]))<50:
			checkpoint_id = i
			checkpoint_on = true
			health = 3
			persist_checkpoint()
			Audio.cue("checkpoint")
			checkpoint_saved.emit()
	if not receiver_on and meets(level.requires):
		receiver_on = true
		Audio.cue("gate")
		message_requested.emit("The way is open")
		persist_checkpoint()
	update_solids()
	if receiver_on and hero.position.distance_to(level.exit)<55:
		is_finished = true
		hero.frozen = true
		hero.sprite.play("celebrate")
		effects.burst(hero.position-Vector2(0,40),GOLD,60,200)
		finished.emit(collected.size(),deaths)
	if elapsed-last_notice>60 and not auto_hint_shown:
		auto_hint_shown = true
		message_requested.emit("Need a clue? Tap ? for free step-by-step hints.")
	queue_redraw()

func step_object(data: Dictionary, delta: float) -> void:
	var uid = str(data.id)
	var kind = str(data.kind)
	var location = point(data.pos)
	if kind=="key" and not flags.get(uid,false) and meets(data.needs) and hero.position.distance_to(location)<55:
		mark(uid)
		message_requested.emit(str(data.label)+" collected")
	elif kind=="plate":
		flags[uid] = absf(hero.position.x-location.x)<45 and absf(hero.position.y-location.y)<14
	elif kind=="cage" and not flags.get(uid,false) and meets(data.needs):
		for enemy in mobs:
			if enemy.kind=="moth" and enemy.position.distance_to(location-Vector2(0,30))<65:
				enemy.harmless = true
				mark(uid)
	elif kind in ["receiver","reflect","brazier","ice"] and not flags.get(uid,false):
		var required_lens = int(data.get("lens",-1))
		var lit = hero.lantern_on and (meets(data.needs) or data.get("unstable",false)) and (required_lens<0 or lens==required_lens) and can_illuminate(location-Vector2(0,45),300)
		charges[uid] = clampf(float(charges.get(uid,0))+(delta if lit else -delta*.7),0,1.2)
		if float(charges[uid])>=1.19:
			if data.get("unstable",false) and not meets(data.needs):
				flags["fallen_stair"] = true
				charges[uid] = 0
				message_requested.emit("The stair fell safely. Use the winch, then brace it before heating.")
				return
			mark(uid)
			if kind=="ice":temporary[uid] = 12.0
			effects.burst(location-Vector2(0,40),GOLD if kind!="ice" else Color(.5,.87,1),25,100)

func nearest_object() -> String:
	var best = 95.0
	var result = ""
	for uid in objects:
		var o: Dictionary = objects[uid]
		if o.kind in ["key","plate","receiver","reflect","ice","anchor","cage","cover","gauge"]:continue
		if o.kind=="brazier" and not flags.get(uid,false):continue
		if flags.get(uid,false) and o.kind not in ["valve","lens","reset","call","clue","brazier","transfer","npc"]:continue
		var location = crates[uid].position if crates.has(uid) else point(o.pos)
		var distance = hero.position.distance_to(location)
		if distance<best:
			best = distance
			result = uid
	return result

func context_text() -> String:
	if context_id.is_empty():return ""
	var o: Dictionary = objects[context_id]
	if o.kind=="brazier" and flags.get(o.id,false):return "Extinguish the brazier"
	if not meets(o.needs):return "Locked · follow the matching symbol"
	return str(o.label)

func interact(uid: String) -> bool:
	if not objects.has(uid) or is_dead or is_finished:return false
	var o: Dictionary = objects[uid]
	var location = crates[uid].position if crates.has(uid) else point(o.pos)
	if hero.position.distance_to(location)>100:return false
	if not meets(o.needs):
		message_requested.emit("Find the matching key or complete the connected mechanism first.")
		return false
	match str(o.kind):
		"clue":
			clue_read = true
			message_requested.emit("Inscription copied to your journal. Pause to read it.")
		"brazier":
			flags[uid] = false
			charges[uid] = 0
		"transfer":
			values["left"] = (int(values.get("left",1))+1)%4
			values["right"] = 3-int(values.left)
		"npc":
			clue_read = true
			message_requested.emit(str(o.get("dialogue",level.story)))
		"lens":
			lens = (lens+1)%3 if int(level.id)>=35 else 1
			message_requested.emit("Lantern lens · "+lens_name())
		"reset":reset_local()
		"call":
			for vehicle in vehicles:
				if vehicle.data.id==o.vehicle:
					vehicle.body.position = point(vehicle.data.nodes[int(o.dock)])
					vehicle.stop = int(o.dock)
					vehicle.wait = 4.0
		"crate":
			grabbed_crate = uid
			return true
		"mirror","ring","star":
			var count = 3 if o.kind=="ring" else 4
			values[uid] = (int(values.get(uid,0))+1)%count
			if int(values[uid])==int(o.target):
				if not o.get("wrong",false):mark(uid)
				else:message_requested.emit("A hollow chime · this star has no live cable")
		"valve":
			if o.get("water_control",false):values[uid] = (int(values.get(uid,0))+1)%3
			else:values[uid] = 1
			if int(values[uid])==int(o.get("target",1)):mark(uid)
		"door","lever":
			if o.get("reset",false):reset_local()
			else:mark(uid)
		_:return false
	Audio.cue("tap")
	persist_checkpoint()
	return true

func update_solids() -> void:
	for row in platforms:
		var broken = float(brittle.get(str(row.data.get("break_id","")),0))>=2
		row.body.collision_layer = 1 if meets(row.data.get("needs",[])) and not broken else 0
		if row.data.has("falls_if"):
			row.body.position.y = float(row.data.y)+(130 if flags.get(row.data.falls_if,false) and not flags.get("brace",false) else 0)
	for uid in objects:
		var o: Dictionary = objects[uid]
		if o.has("ice_body"):o.ice_body.collision_layer = 1 if flags.get(uid,false) else 0
	gate_body.collision_layer = 0 if receiver_on else 1

func step_vehicle(vehicle: Dictionary, delta: float) -> void:
	if not meets(vehicle.data.needs):return
	vehicle.wait = maxf(0,float(vehicle.wait)-delta)
	if float(vehicle.wait)>0:return
	var nodes: Array = vehicle.data.nodes
	var next = int(vehicle.stop)+int(vehicle.direction)
	if next<0 or next>=nodes.size():
		vehicle.direction = -int(vehicle.direction)
		next = int(vehicle.stop)+int(vehicle.direction)
	var destination = point(nodes[next])
	vehicle.body.position = vehicle.body.position.move_toward(destination,95*delta)
	if vehicle.body.position.distance_to(destination)<2:
		vehicle.stop = next
		vehicle.wait = 3.0

func water_top(zone: Dictionary) -> float:
	var surface = float(zone.rect[1])
	if zone.has("levels"):surface = float(zone.levels[clampi(int(values.get(str(zone.get("control","water")),0)),0,zone.levels.size()-1)])
	if flags.get(str(zone.get("raise_flag","__none")),false):surface -= float(zone.get("rise",0))
	return surface

func surface_at(location: Vector2) -> float:
	for z in level.zones:
		if z.kind=="water" and location.x>float(z.rect[0]) and location.x<float(z.rect[0])+float(z.rect[2]):return water_top(z)
	return INF

func process_zone(z: Dictionary, _delta: float) -> void:
	var rect = Rect2(z.rect[0],z.rect[1],z.rect[2],z.rect[3])
	var body_point = hero.position-Vector2(0,25)
	if z.kind=="water":
		if hero.position.x>rect.position.x and hero.position.x<rect.end.x and hero.position.y>water_top(z)+5 and hero.position.y<rect.end.y+60:
			hero.wet = true
			hero.wind.x += float(z.get("current",0))*(-1 if flags.get(str(z.get("reverse_flag","__none")),false) else 1)
	elif z.kind=="brittle":
		var uid = str(z.uid)
		if brittle.has(uid):brittle[uid] = float(brittle[uid])+_delta
		elif hero.position.x>rect.position.x and hero.position.x<rect.end.x and absf(hero.position.y-rect.position.y)<14:brittle[uid] = .01
	elif z.kind=="wind" and rect.has_point(body_point):
		hero.wind += point(z.force)
	elif z.kind=="lava" and rect.has_point(hero.position-Vector2(0,5)):die()
	elif z.kind in ["vent","pressure"] and not flags.get(str(z.get("disable","")),false):
		var cycle = fmod(time+float(z.rect[0])*.001,4.8)
		var active = cycle>1.0 and cycle<2.6
		if z.get("reverse",false):active = cycle>3.3
		if active and rect.has_point(body_point):hurt(rect.get_center())

func covered(player: Vector2, threat: Vector2) -> bool:
	for cp in level.checkpoints:
		if player.distance_to(point(cp))<80:return true
	for o in objects.values():
		if o.kind=="lens" and player.distance_to(point(o.pos))<100:return true
	for o in objects.values():
		if o.kind=="cover":
			var p = point(o.pos)
			if absf(player.y-p.y)<85 and absf(threat.y-p.y)<95 and (player.x-p.x)*(threat.x-p.x)<0:return true
	return false

func lure_for(kind: String) -> Vector2:
	if kind=="wasp":return Vector2.INF
	if kind=="moth" and objects.has("cage") and flags.get("decoy",false):return point(objects.cage.pos)
	if objects.has("decoy") and flags.get("decoy",false) and not flags.get("phase3",false):return point(objects.decoy.pos)
	return Vector2.INF

func any_heat() -> bool:
	for o in objects.values():
		if o.kind=="brazier" and flags.get(o.id,false):return true
	return false

func enemy_impact(location: Vector2, _kind: String) -> void:
	for o in objects.values():
		if o.kind=="anchor" and meets(o.needs) and location.distance_to(point(o.pos)-Vector2(0,25))<100:mark(str(o.id))

func can_illuminate(target: Vector2, radius: float) -> bool:
	var origin = hero.position+Vector2(hero.facing*20,-42)
	var offset = target-origin
	if offset.length()>radius or offset.x*hero.facing < -35 or absf(offset.y)>150:return false
	var hit = get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin,target,1))
	return hit.is_empty()

func update_camera(snap = false) -> void:
	var size = get_viewport_rect().size
	camera.position = Vector2(clampf(hero.position.x+hero.facing*110,size.x/2,maxf(size.x/2,float(level.width)-size.x/2)),clampf(hero.position.y-120,size.y/2,maxf(size.y/2,float(level.height)-size.y/2)))
	if snap:camera.reset_smoothing()

func hurt(source: Vector2) -> void:
	if is_dead or is_finished or hero.protection>0 or covered(hero.position,source):return
	health -= 1
	hero.protection = 1.2
	hero.velocity += Vector2(signf(hero.position.x-source.x)*150,-180)
	effects.burst(hero.position-Vector2(0,30),Color(1,.4,.3),18,100)
	Audio.cue("hurt")
	status_changed.emit()
	if health<=0:die()

func die() -> void:
	if is_dead or is_finished:return
	is_dead = true
	deaths += 1
	hero.frozen = true
	persist_checkpoint()
	Audio.cue("hurt")
	died.emit()

func retry() -> void:
	apply_snapshot(checkpoint_snapshot)
	hero.reset_at(point(level.checkpoints[checkpoint_id]))
	health = 3
	is_dead = false
	for enemy in mobs:enemy.reset_pose()
	status_changed.emit()

func revive() -> void:
	if revived or not is_dead:return
	revived = true
	hero.reset_at(point(level.checkpoints[checkpoint_id]))
	health = 3
	is_dead = false

func snapshot() -> Dictionary:
	var positions = {}
	for uid in crates:positions[uid] = [crates[uid].position.x,crates[uid].position.y]
	return {"level":int(level.id),"checkpoint":checkpoint_on,"checkpoint_id":checkpoint_id,"collected":collected.keys(),"flags":flags.duplicate(),"values":values.duplicate(),"crates":positions,"receiver":receiver_on,"secret":secret_found,"clue":clue_read,"lens":lens,"deaths":deaths,"elapsed":elapsed}

func apply_snapshot(saved: Dictionary) -> void:
	brittle.clear()
	flags = saved.get("flags",{}).duplicate()
	values.merge(saved.get("values",{}),true)
	collected.clear()
	for uid in saved.get("collected",[]):collected[str(uid)] = true
	checkpoint_id = clampi(int(saved.get("checkpoint_id",0)),0,level.checkpoints.size()-1)
	checkpoint_on = checkpoint_id>0
	receiver_on = bool(saved.get("receiver",false))
	secret_found = bool(saved.get("secret",false))
	clue_read = bool(saved.get("clue",false))
	lens = clampi(int(saved.get("lens",lens)),0,2 if int(level.id)>=35 else (1 if int(level.id)>=21 else 0))
	deaths = int(saved.get("deaths",0))
	elapsed = float(saved.get("elapsed",0))
	for uid in saved.get("crates",{}):
		if crates.has(uid):crates[uid].position = point(saved.crates[uid])
	for uid in flags:
		if objects.has(uid) and objects[uid].kind=="ice":temporary[uid] = 12.0
	update_solids()

func persist_checkpoint() -> void:
	if is_finished or hero==null:return
	checkpoint_snapshot = snapshot()
	Save.data.resume = checkpoint_snapshot.duplicate(true)
	Save.write()

func reset_local() -> void:
	grabbed_crate = ""
	brittle.clear()
	flags.erase("fallen_stair")
	for uid in crates:
		if not flags.get(uid,false):crates[uid].position = crates[uid].home
	for uid in objects:
		if not flags.get(uid,false) and objects[uid].kind in ["mirror","ring","star"]:values[uid] = 0
	for enemy in mobs:enemy.reset_pose()
	hero.protection = 2
	message_requested.emit("Loose objects reset · quest items and open locks kept")

func lens_name() -> String:
	return ["Light","Ember","Frost"][lens]

func show_hint() -> void:
	hint_step = mini(3,hint_step+1)
	hint_time = 10
	var texts = ["Follow the symbols and the cable leading to the exit.",str(level.story),str(level.clue)]
	message_requested.emit("Hint "+str(hint_step)+" · "+texts[hint_step-1])

func journal_text() -> String:
	var remaining: Array[String] = []
	for uid in level.requires:
		if not meets([uid]):remaining.append(str(uid).replace("_"," "))
	return str(level.objective)+"\n\n"+(str(level.clue) if clue_read or hint_step>=3 else "Find the trail inscription, or use free hints.")+"\n\nExit mechanisms remaining: "+(", ".join(remaining) if not remaining.is_empty() else "All open")+"\n\nLens: "+lens_name()+" · Memory: "+("Found" if secret_found else "Undiscovered")

func _draw() -> void:
	if level.is_empty():return
	for row in platforms:
		var data: Dictionary = row.data
		var rect = Rect2(row.body.position,Vector2(data.w,data.h))
		if int(row.body.collision_layer)==0:
			draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color(1,.82,.42,.16),2,true)
		else:draw_platform(rect,str(data.get("material","moss")))
	for vehicle in vehicles:
		var p: Vector2 = vehicle.body.position
		draw_rect(Rect2(p+Vector2(-95,0),Vector2(190,24)),Color(.30,.23,.15))
		for x in range(-90,95,18):draw_rect(Rect2(p+Vector2(x,0),Vector2(16,22)),Color(.63,.49,.29),false,2)
		draw_line(p+Vector2(-90,-10),p+Vector2(90,-10),Color(1,.8,.42),3,true)
	for z in level.zones:draw_zone(z)
	for uid in objects:
		var o: Dictionary = objects[uid]
		if o.kind=="crate":
			draw_arc(point(o.target)-Vector2(0,5),30,0,PI,24,Color(.9,.8,.5,.5),2,true)
			continue
		draw_object(o)
	for i in range(level.checkpoints.size()):
		var cp = point(level.checkpoints[i])
		draw_texture_rect(CHECKPOINT,Rect2(cp-Vector2(30,80),Vector2(60,80)),false,Color.WHITE if i<=checkpoint_id else Color(.7,.8,.8))
	for i in range(5):
		if not collected.has(str(i)):draw_firefly(point(level.fireflies[i])+Vector2(0,sin(time*2+i)*7))
	if not secret_found:
		var p = level.secret-Vector2(0,35)
		draw_circle(p,26,Color(.4,.8,1,.10))
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-20),p+Vector2(15,0),p+Vector2(0,20),p+Vector2(-15,0)]),Color(.57,.85,1))
	var exit_point: Vector2 = level.exit
	draw_texture_rect(GATE,Rect2(exit_point-Vector2(105,258),Vector2(210,258)),false,Color(1,1,1,.5 if receiver_on else 1))
	for uid in level.requires:
		if objects.has(str(uid)):
			var source = point(objects[str(uid)].pos)-Vector2(0,50)
			if source.distance_to(exit_point)<800:draw_line(source,exit_point-Vector2(0,100),Color(1,.77,.35,.55 if meets([uid]) else .16),2,true)
	if receiver_on:
		draw_rect(Rect2(exit_point-Vector2(49,132),Vector2(98,132)),Color(1,.74,.24,.20))
		draw_arc(exit_point-Vector2(0,100),54,PI,TAU,32,GOLD,4,true)
	else:
		for i in range(level.requires.size()):
			var p = exit_point+Vector2((i-(level.requires.size()-1)*.5)*22,-175)
			draw_circle(p,7,GOLD if meets([level.requires[i]]) else Color(.22,.29,.31))
	if hero!=null and hero.lantern_on:
		var origin = hero.position+Vector2(hero.facing*27,-35)
		var color = [GOLD,Color(1,.4,.15),Color(.45,.84,1)][lens]
		for i in range(10,0,-1):draw_circle(origin,i*10,Color(color,.006*(11-i)))
		draw_colored_polygon(PackedVector2Array([origin,origin+Vector2(hero.facing*270,-110),origin+Vector2(hero.facing*280,80)]),Color(color,.06))
	if hero!=null and hero.gliding:
		var p = hero.position-Vector2(0,110)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-75,20),p+Vector2(-40,-15),p+Vector2(0,-30),p+Vector2(40,-15),p+Vector2(75,20)]),Color(.46,.67,.44,.94))
		draw_line(p+Vector2(-65,15),hero.position-Vector2(0,40),Color(.86,.76,.47),1.5,true)
		draw_line(p+Vector2(65,15),hero.position-Vector2(0,40),Color(.86,.76,.47),1.5,true)
	if hint_time>0:
		var target = hint_target()
		draw_arc(target-Vector2(0,55),38+sin(time*5)*4,0,TAU,36,GOLD,3,true)

func draw_platform(rect: Rect2, material = "moss") -> void:
	var tint = Color(1,.98,.92)
	if material=="basalt":tint = Color(.68,.50,.45)
	elif material=="ice":tint = Color(.62,.85,1)
	elif material=="stone":tint = Color(.8,.85,.89)
	elif material=="light":
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,18)),Color(1,.76,.24,.30))
		draw_line(rect.position,rect.position+Vector2(rect.size.x,0),GOLD,3,true)
		return
	var chunks = maxi(1,int(ceil(rect.size.x/310)))
	for i in range(chunks):
		var w = rect.size.x/chunks
		draw_texture_rect(PLATFORM,Rect2(rect.position+Vector2(i*w-5,-46),Vector2(w+10,rect.size.y+35)),false,tint)
	if material=="ice":draw_line(rect.position,rect.position+Vector2(rect.size.x,0),Color(.75,.92,1),6,true)

func draw_zone(z: Dictionary) -> void:
	var r = Rect2(z.rect[0],z.rect[1],z.rect[2],z.rect[3])
	if z.kind=="water":
		var top = water_top(z)
		draw_rect(Rect2(r.position.x,top,r.size.x,maxf(0,r.end.y-top)),Color(.08,.52,.64,.28))
		var line = PackedVector2Array()
		for i in range(int(r.size.x/20)+1):line.append(Vector2(r.position.x+i*20,top+sin(time*2+i*.7)*3))
		draw_polyline(line,Color(.5,.9,1,.8),2,true)
		for i in range(12):
			var p = Vector2(r.position.x+fmod(i*157+time*15,r.size.x),r.end.y-fmod(time*23+i*41,maxf(30,r.end.y-top)))
			draw_arc(p,3,0,TAU,12,Color(.7,.95,1,.3),1,true)
	elif z.kind=="lava":
		draw_rect(r,Color(.85,.19,.045,.9))
		for x in range(0,int(r.size.x),35):draw_circle(Vector2(r.position.x+x,r.position.y+sin(time*2+x)*4),22,Color(1,.54,.12,.8))
	elif z.kind=="brittle":
		var amount = float(brittle.get(str(z.uid),0))
		if amount<2:
			for x in range(0,int(r.size.x),35):draw_line(r.position+Vector2(x,-4),r.position+Vector2(x+17,10),Color(1,.7,.3,.5+amount*.2),2,true)
	elif z.kind=="wind":
		for i in range(5):
			var y = r.position.y+40+i*60
			var x = r.position.x+fmod(time*80+i*100,maxf(1,r.size.x-50))
			draw_line(Vector2(x,y),Vector2(x+55,y-8),Color(.8,.94,1,.3),2,true)
	elif z.kind=="smoke" and not flags.get(str(z.get("disable","")),false):
		draw_rect(r,Color(.19,.20,.27,.48))
	elif z.kind in ["vent","pressure"]:
		var disabled = flags.get(str(z.get("disable","")),false)
		var cycle = fmod(time+float(z.rect[0])*.001,4.8)
		var hot = not disabled and ((cycle>1 and cycle<2.6) if not z.get("reverse",false) else cycle>3.3)
		var col = Color(1,.4,.1) if z.kind=="vent" else Color(.4,.83,1)
		draw_rect(Rect2(r.position.x,r.end.y-18,r.size.x,18),Color(.22,.26,.29))
		if not disabled:
			draw_arc(Vector2(r.position.x+20,r.end.y-30),15,-PI/2,-PI/2+TAU*cycle/4.8,24,col,3,true)
			if hot:
				for i in range(6):draw_line(Vector2(r.position.x+i*r.size.x/6,r.end.y),Vector2(r.position.x+i*r.size.x/6+sin(time*12+i)*8,r.position.y),Color(col,.65),10,true)

func draw_object(o: Dictionary) -> void:
	var p = point(o.pos)
	var uid = str(o.id)
	var done = bool(flags.get(uid,false))
	var kind = str(o.kind)
	var col = GOLD if done else Color(.72,.77,.73)
	if kind=="key" and done:return
	if kind=="key" and not meets(o.needs):draw_string(FONT,p+Vector2(-24,-85),"LOCKED",HORIZONTAL_ALIGNMENT_LEFT,-1,12,GOLD)
	if kind=="npc":
		var frame = int(time*3)%4
		draw_texture_rect_region(HERO_ART,Rect2(p-Vector2(52,112),Vector2(104,112)),Rect2(frame*352,0,352,320),Color(.73,.89,.86))
		draw_string(FONT,p+Vector2(-40,-122),str(o.get("role","TRAVELER")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,GOLD)
	elif kind in ["receiver","reflect","brazier","ice"]:
		if kind=="receiver":draw_texture_rect(RECEIVER,Rect2(p-Vector2(36,82),Vector2(72,82)),false)
		elif kind=="ice":
			draw_circle(p-Vector2(0,25),20,Color(.4,.85,1,.2))
			for angle in range(0,360,60):draw_line(p-Vector2(0,25),p-Vector2(0,25)+Vector2.from_angle(deg_to_rad(angle))*20,Color(.6,.9,1),2,true)
			if done:
				draw_rect(Rect2(p+Vector2(-95,-10),Vector2(190,22)),Color(.5,.83,1,.9))
				draw_line(p+Vector2(-95,-10),p+Vector2(95,-10),Color(.8,.95,1),3,true)
		elif kind=="brazier":
			draw_rect(Rect2(p+Vector2(-19,-38),Vector2(38,38)),Color(.36,.29,.21))
			if done:
				for i in range(3):draw_circle(p+Vector2((i-1)*10,-50-sin(time*9+i)*6),13,Color(1,.4+i*.12,.12,.8))
			else:draw_circle(p-Vector2(0,48),14,Color(.7,.35,.16))
		else:
			draw_line(p+Vector2(-45,-8),p+Vector2(45,-8),Color(.45,.88,1),4,true)
			draw_line(p+Vector2(-35,-70),p-Vector2(0,8),Color(1,.83,.45,.4),2,true)
			draw_line(p-Vector2(0,8),p+Vector2(45,-100),Color(1,.83,.45,.6 if done else .1),2,true)
		var progress = 1.0 if done else float(charges.get(uid,0))/1.2
		if progress>0:draw_arc(p-Vector2(0,52),28,-PI/2,-PI/2+TAU*progress,32,GOLD if kind!="ice" else Color(.5,.9,1),3,true)
	elif kind=="key":
		draw_circle(p-Vector2(0,45+sin(time*3)*5),20,Color(1,.8,.3,.1))
		draw_arc(p-Vector2(0,48),10,0,TAU,20,GOLD,4,true)
		draw_line(p-Vector2(0,38),p-Vector2(0,15),GOLD,5,true)
		draw_line(p-Vector2(0,20),p+Vector2(10,-20),GOLD,4,true)
	elif kind=="cover":
		draw_rect(Rect2(p+Vector2(-23,-112),Vector2(46,112)),Color(.17,.24,.25))
		for y in [-110,-75,-40]:draw_line(p+Vector2(-25,y),p+Vector2(25,y),Color(.43,.53,.5),4,true)
	elif kind in ["mirror","ring","star","valve","lens","gauge","transfer"]:
		draw_rect(Rect2(p+Vector2(-14,-28),Vector2(28,28)),Color(.25,.29,.27))
		draw_circle(p-Vector2(0,50),27,Color(.08,.16,.20))
		draw_arc(p-Vector2(0,50),27,0,TAU,32,col,2,true)
		var angle = int(values.get(uid,0))*PI/2
		if kind in ["mirror","star"]:
			var v = Vector2.from_angle(angle+PI/4)*21
			draw_line(p-Vector2(0,50)-v,p-Vector2(0,50)+v,Color(.75,.94,1),5,true)
		elif kind=="ring":
			var text = ["LEAF","MOON","SUN"][int(values.get(uid,0))%3]
			draw_string(FONT,p+Vector2(-19,-46),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,col)
		else:
			for i in range(4):
				var v = Vector2.from_angle(i*PI/2+angle*.4)*20
				draw_line(p-Vector2(0,50),p-Vector2(0,50)+v,col,3,true)
			if kind=="gauge" or (kind=="valve" and o.get("water_control",false)):draw_string(FONT,p+Vector2(-4,-46),str(values.get(uid,0)),HORIZONTAL_ALIGNMENT_LEFT,-1,14,GOLD)
	elif kind=="plate":
		draw_rect(Rect2(p+Vector2(-40,-9),Vector2(80,9)),col)
	elif kind=="anchor":
		draw_rect(Rect2(p+Vector2(-30,-70),Vector2(60,70)),Color(.35,.32,.23))
		draw_polyline(PackedVector2Array([p+Vector2(-15,-66),p+Vector2(7,-42),p+Vector2(-3,-25),p+Vector2(15,-5)]),GOLD if done else Color(.7,.6,.38),3,true)
	elif kind=="cage":
		for x in range(-30,31,15):draw_line(p+Vector2(x,-70),p+Vector2(x,0),col,2,true)
		draw_line(p+Vector2(-35,-70),p+Vector2(35,-70),col,3,true)
	else:
		draw_rect(Rect2(p+Vector2(-23,-48),Vector2(46,48)),Color(.18,.25,.26))
		if kind in ["lever","door"]:
			draw_line(p+Vector2(0,-22),p+Vector2(20 if done else -20,-65),col,5,true)
			draw_circle(p+Vector2(20 if done else -20,-65),6,col)
		else:
			var glyph = {"clue":"?","reset":"↻","call":"↑"}.get(kind,"•")
			draw_string(FONT,p+Vector2(-8,-18),glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,23,col)
	if done and kind not in ["cover","plate"]:draw_circle(p+Vector2(25,-75),5,GOLD)
	if context_id==uid:
		draw_arc(p-Vector2(0,35),49,0,TAU,40,Color(1,.88,.54,.7),1.5,true)

func draw_firefly(p: Vector2) -> void:
	draw_circle(p,20,Color(1,.72,.2,.08))
	draw_circle(p,8,Color(1,.78,.3,.22))
	var wing = sin(time*14)*2
	draw_circle(p+Vector2(-5,-3),3+wing*.3,Color(1,.93,.65,.8))
	draw_circle(p+Vector2(5,-3),3-wing*.3,Color(1,.93,.65,.8))
	draw_circle(p,3.5,GOLD)

func hint_target() -> Vector2:
	for uid in level.requires:
		if not meets([uid]):return requirement_target(str(uid),0)
	return level.exit

func requirement_target(uid: String, depth: int) -> Vector2:
	var key = uid.trim_prefix("!").split(":")[0]
	if not objects.has(key) or depth>8:return level.exit
	var o: Dictionary = objects[key]
	if o.kind=="gauge" and objects.has("transfer"):return point(objects.transfer.pos)
	for dependency in o.needs:
		if not meets([dependency]):return requirement_target(str(dependency),depth+1)
	return point(o.pos)

func enemy_visible(enemy: LanternEnemy) -> bool:
	for z in level.zones:
		if z.kind=="smoke" and not flags.get(str(z.get("disable","")),false):
			if Rect2(z.rect[0],z.rect[1],z.rect[2],z.rect[3]).has_point(enemy.position):return false
	return true
