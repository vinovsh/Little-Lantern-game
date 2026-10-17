extends Node
var checks := 0
var failures: Array[String] = []
var save: Node
var game: Node
var previous: Dictionary
class AdMock extends RefCounted:
	func is_rewarded_ready() -> bool: return true
	func is_interstitial_ready() -> bool: return true
	func show_rewarded(_placement: String, _token: String) -> void: pass
	func show_interstitial() -> void: pass

func _ready() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL ",message)

func run() -> void:
	await get_tree().process_frame
	save = get_tree().root.get_node("Save")
	previous = save.data.duplicate(true)
	save.data = save.defaults()
	check(LanternLevels.validate().is_empty(),"All ten level layouts respect jump budgets")
	check(save.unlocked(1) and not save.unlocked(2),"Only first level starts unlocked")
	check(save.complete(1,5,0) == 3,"Perfect completion awards three stars")
	check(save.unlocked(2),"Completing a level unlocks the next")
	save.complete(1,1,4)
	check(save.best(1).stars == 3 and save.best(1).fireflies == 5,"Replaying never decreases best results")
	check(save.write(),"Progress commits to device storage")
	save.load_progress()
	check(save.best(1).stars == 3,"Progress survives reload")
	var malformed: Dictionary = save.defaults()
	malformed.levels = {"1": {"stars": 99,"fireflies": -8,"completed":true}, "500": {"stars":3}}
	malformed.settings.music = -3
	var clean: Dictionary = save.sanitize(malformed)
	check(clean.levels["1"].stars == 3 and clean.levels["1"].fireflies == 0 and not clean.levels.has("500"),"Invalid progress is clamped and unknown levels rejected")
	check(clean.settings.music == 0,"Invalid settings are bounded")
	malformed.levels["1"].stars = {"invalid":true}
	malformed.resume = {"level": 1,"elapsed":{},"deaths":[],"collected":["0","0","bad"]}
	clean = save.sanitize(malformed)
	check(clean.levels["1"].stars == 0 and clean.resume.deaths == 0 and clean.resume.elapsed == 0.0 and clean.resume.collected == ["0"],"Malformed numeric save values and duplicate collectibles are sanitized")
	check(not save.valid({"schema_version":999}),"Unsupported schema is rejected")
	# Corrupt primary and verify recovery from a known valid backup.
	save.write()
	var file := FileAccess.open(save.PATH,FileAccess.WRITE)
	file.store_string("broken json")
	file.close()
	save.load_progress()
	check(save.best(1).stars == 3,"Corrupt primary recovers from backup")
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	for index in range(1,11):
		await game.start_level(index)
		await get_tree().physics_frame
		var world: LanternWorld = game.world
		check(world.level.id == index and world.hero != null,"Level %d instantiates" % index)
		for i in range(8): await get_tree().physics_frame
		check(world.hero.is_on_floor(),"Level %d spawn lands on a platform" % index)
		check(not world.is_dead,"Level %d spawn is safe" % index)
		Input.action_press("right")
		var before: Vector2 = world.hero.position
		for i in range(12): await get_tree().physics_frame
		Input.action_release("right")
		check(world.hero.position.x > before.x + 20,"Level %d player movement advances" % index)
		Input.action_press("jump")
		for i in range(10): await get_tree().physics_frame
		Input.action_release("jump")
		check(world.hero.position.y < before.y - 35,"Level %d jump rises" % index)
		# Reveal through actual light detection and normal physics update.
		world.hero.reset_at(Vector2(world.level.bridge.position.x-60,world.level.bridge.position.y-1))
		world.hero.facing = 1
		for i in range(5): await get_tree().physics_frame
		check(world.bridge_on and world.bridge_body.collision_layer == 1,"Level %d lantern reveals a solid bridge" % index)
		world.hero.reset_at(world.level.checkpoint + Vector2(0,-1))
		for i in range(5): await get_tree().physics_frame
		check(world.checkpoint_on and save.data.resume.get("checkpoint",false),"Level %d checkpoint persists" % index)
		world.hero.reset_at(world.level.receiver - Vector2(120,1))
		world.hero.facing = 1
		for i in range(45): await get_tree().physics_frame
		check(world.receiver_on,"Level %d receiver opens after illumination" % index)
		world.die()
		check(world.is_dead and world.deaths == 1,"Level %d death is recorded once" % index)
		world.die()
		check(world.deaths == 1,"Level %d duplicate deaths ignored" % index)
		world.retry()
		check(not world.is_dead and world.hero.position.distance_to(world.level.checkpoint)<5,"Level %d free retry restores checkpoint" % index)
		check(not world.receiver_on,"Level %d retry restores checkpoint puzzle state" % index)
		world.die()
		world.revive()
		check(not world.is_dead and world.revived and world.hero.protection >= 1.9,"Level %d earned revive protects player" % index)
		world.receiver_on = true
		world.hero.reset_at(world.level.exit + Vector2(0,-1))
		for i in range(4): await get_tree().physics_frame
		check(world.is_finished,"Level %d exit completes with receiver powered" % index)
		world.persist_checkpoint()
		check(save.data.resume.is_empty(),"Level %d completed results cannot restore an obsolete checkpoint" % index)
		game.show_map()
		await get_tree().process_frame
	# Test UI pause, settings values, and untouched offline advertising state.
	await game.start_level(1)
	for i in range(10): await get_tree().physics_frame
	var starting_x: float = game.world.hero.position.x
	var starting_y: float = game.world.hero.position.y
	touch(0,Vector2(game.margin_left+140,game.screen_height-64),true)
	touch(1,Vector2(game.screen_width-game.margin_right-150,game.screen_height-64),true)
	for i in range(12): await get_tree().physics_frame
	check(game.world.hero.position.x > starting_x+20 and game.world.hero.position.y < starting_y-35,"Two simultaneous touch controls move and jump")
	touch(0,Vector2(game.margin_left+140,game.screen_height-64),false)
	touch(1,Vector2(game.screen_width-game.margin_right-150,game.screen_height-64),false)
	check(not Input.is_action_pressed("right") and not Input.is_action_pressed("jump"),"Releasing both touches clears their actions")
	game.show_pause()
	check(game.world.process_mode == Node.PROCESS_MODE_DISABLED,"Pause stops gameplay")
	game.show_settings("pause")
	check(game.state == "settings","Settings opens from pause")
	game.close_settings()
	check(game.state == "pause","Settings returns to paused gameplay")
	game.resume_game()
	check(game.state == "playing","Resume restores gameplay")
	check(not get_tree().root.get_node("Ads").rewarded_ready(),"No fake ad availability without a bridge")
	var ads: Node = get_tree().root.get_node("Ads")
	ads.bridge = AdMock.new()
	game.world.die()
	game.request_reward("revive")
	check(game.world.process_mode == Node.PROCESS_MODE_DISABLED,"Ad presentation freezes gameplay")
	ads._on_reward("revive","stale-token")
	check(game.world.is_dead,"Stale earned callbacks are ignored")
	var token: String = game.reward_token
	ads._on_reward("revive",token)
	check(game.world.revived and not game.world.is_dead,"Earned callback grants a revive")
	ads._on_reward("revive",token)
	check(ads.consumed.size() == 1,"Duplicate earned callbacks are consumed once")
	ads._on_closed()
	check(game.state == "playing","Ad dismissal resumes earned gameplay")
	game.show_pause()
	ads._on_closed()
	check(game.state == "pause","Duplicate dismissal cannot resume a paused game")
	game.resume_game()
	game.world.revived = false
	game.world.die()
	game.request_reward("revive")
	var late_token: String = game.reward_token
	ads._on_closed()
	check(game.world.is_dead,"Dismissal without an earned event grants no reward")
	ads._on_reward("revive",late_token)
	check(game.world.revived and game.state == "playing","A late valid earned event is applied after dismissal")
	ads.bridge = null
	ads.invalidate()
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state == "pause" and not game.focused,"Focus loss pauses and clears controls")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.state == "pause" and game.focused,"Focus return requires explicit Resume")
	save.data = previous
	save.write()
	game.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	Audio.shutdown()
	await get_tree().process_frame
	await get_tree().process_frame
	print("TEST_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	get_tree().quit.call_deferred(0 if failures.is_empty() else 1)

func touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	get_tree().root.push_input(event,true)
