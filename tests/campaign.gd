extends Node
var checks = 0
var failures: Array[String] = []
var game: Node
var previous: Dictionary
func _ready() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL ",message)
func wait_frames(count: int) -> void:
	for i in range(count):await get_tree().physics_frame
func place(world: LanternWorld, location: Vector2) -> void:
	world.hero.reset_at(location)
	world.hero.frozen = true
	world.hero.protection = 999
func satisfy(world: LanternWorld, requirement: String, depth = 0) -> bool:
	if world.meets([requirement]):return true
	if depth>12:return false
	var parts = requirement.split(":")
	var uid = parts[0]
	if not world.objects.has(uid):
		for rule in world.level.rules:
			if rule.sets==uid:
				for dep in rule.needs:
					if not await satisfy(world,str(dep),depth+1):return false
				await wait_frames(2)
				return world.meets([requirement])
		return false
	var o: Dictionary = world.objects[uid]
	for dep in o.needs:
		if not await satisfy(world,str(dep),depth+1):return false
	if parts.size()>1:
		place(world,world.point(world.objects.transfer.pos) if o.kind=="gauge" else world.point(o.pos))
		for i in range(4):
			if world.meets([requirement]):break
			world.interact("transfer" if o.kind=="gauge" else uid)
		return world.meets([requirement])
	var pos = world.point(o.pos)
	match str(o.kind):
		"key","plate":
			place(world,pos)
			await wait_frames(3)
		"crate":
			for dep in o.get("when",[]):
				if not await satisfy(world,str(dep),depth+1):return false
			var crate: LanternCrate = world.crates[uid]
			if o.get("buoyant",false):
				for i in range(480):
					if absf(crate.position.y-world.surface_at(crate.position))<12:break
					await get_tree().physics_frame
			# Simulate a real held use action and horizontal controller input.
			world.hero.reset_at(crate.position-Vector2(65,0))
			world.hero.protection = 999
			world.hero.touch_direction = 1
			Input.action_press("interact")
			for i in range(360):
				if world.flags.get(uid,false):break
				world.hero.protection = 999
				await get_tree().physics_frame
			if not world.flags.get(uid,false):print("CRATE_DIAGNOSTIC ",uid," hero=",world.hero.position," crate=",crate.position," target=",o.target," context=",world.context_id," frozen=",world.hero.frozen)
			Input.action_release("interact")
			world.hero.touch_direction = 0
			world.hero.frozen = true
		"receiver","brazier","reflect","ice":
			for dep in o.get("when",[]):
				if not await satisfy(world,str(dep),depth+1):return false
			world.lens = int(o.get("lens",0))
			place(world,pos-Vector2(90,0))
			world.hero.facing = 1
			world.hero.lantern_on = true
			await wait_frames(82)
		"anchor","cage":
			place(world,pos+Vector2(100,0))
			world.hero.lantern_on = false
			for i in range(700):
				if world.flags.get(uid,false):break
				await get_tree().physics_frame
		_:
			place(world,pos)
			for i in range(5):
				if world.flags.get(uid,false):break
				world.interact(uid)
	await wait_frames(2)
	return world.meets([requirement])
func run() -> void:
	previous = Save.data.duplicate(true)
	Save.data = Save.defaults()
	check(LanternLevels.validate().is_empty(),"Forty authored layouts have unique geometry and complete objectives")
	var old = {"schema_version":1,"revision":12,"levels":{"10":{"completed":true,"stars":3}},"settings":{"music":.2,"effects":.7},"resume":{"level":7}}
	var migrated = Save.sanitize(old)
	check(migrated.schema_version==2 and migrated.legacy_unlocked==10 and migrated.levels.is_empty() and migrated.resume.is_empty() and migrated.settings.music==.2,"Classic saves retain settings and access but do not award new campaign stars")
	var unsafe = Save.defaults()
	unsafe.resume = {"level":1,"flags":{"unknown":true,"bridge":true},"values":{"branch":{}},"crates":{"branch":["bad",[]]},"collected":["0","0","8"],"elapsed":{},"checkpoint_id":999}
	var clean = Save.sanitize(unsafe)
	check(not clean.resume.flags.has("unknown") and clean.resume.collected==["0"] and clean.resume.crates.is_empty(),"Malformed and unknown save state is rejected")
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var only = 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):only = int(arg.trim_prefix("--only="))
	for index in range(1,41):
		if only>0 and index!=only:continue
		await game.start_level(index)
		var world: LanternWorld = game.world
		await wait_frames(14)
		check(world.hero.is_on_floor(),"Level %d has a grounded safe spawn"%index)
		check(not world.is_dead and world.health==3,"Level %d spawn is protected"%index)
		var x = world.hero.position.x
		world.hero.touch_direction = 1
		await wait_frames(20)
		world.hero.touch_direction = 0
		check(world.hero.position.x>x+10,"Level %d accepts horizontal movement"%index)
		var jump_y = world.hero.position.y
		Input.action_press("jump")
		await wait_frames(10)
		Input.action_release("jump")
		check(world.hero.position.y<jump_y-30,"Level %d accepts variable-height jumping"%index)
		world.hero.frozen = true
		for requirement in world.level.requires:
			var ok = await satisfy(world,str(requirement))
			check(ok,"Level %d objective %s is solvable through its mechanics"%[index,requirement])
			if not ok:print("DETAIL ",JSON.stringify({"level":index,"flags":world.flags,"values":world.values}))
		await wait_frames(3)
		check(world.receiver_on,"Level %d opens its exit after all requirements"%index)
		var saved = world.snapshot()
		world.die()
		world.retry()
		check(not world.is_dead and world.health==3 and world.receiver_on,"Level %d retry retains open locks and refills hearts"%index)
		world.apply_snapshot(saved)
		check(world.flags==saved.flags and world.values==saved.values,"Level %d restores puzzle state"%index)
		place(world,world.level.exit)
		await wait_frames(3)
		check(world.is_finished,"Level %d exit completes"%index)
		check(Save.data.resume.is_empty(),"Level %d completion clears obsolete resume"%index)
		print("CAMPAIGN_LEVEL ",index," evaluated")
		game.show_map()
		await get_tree().process_frame
	check(only>0 or Save.unlocked(40),"Completion unlocks the entire forty level campaign")
	Save.data = previous
	Save.write()
	game.queue_free()
	await get_tree().process_frame
	Audio.shutdown()
	await get_tree().process_frame
	print("CAMPAIGN_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	get_tree().quit.call_deferred(0 if failures.is_empty() else 1)
