extends Node
var game: Node
var failures: Array[String] = []
var previous: Dictionary
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	previous = Save.data.duplicate(true)
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	for index in range(1,11):
		await game.start_level(index)
		var world: LanternWorld = game.world
		var jumped_at := -1000
		var jump_frames := 0
		var finished := false
		for tick in range(1600):
			if world.is_dead:
				failures.append("Level %d traversal died at %s" % [index,str(world.hero.position)])
				break
			if world.is_finished:
				finished = true
				break
			var hero: LanternHero = world.hero
			Input.action_press("right")
			# Jump at each authored gap. The hidden crossing is walked once illuminated.
			for i in range(world.level.platforms.size()-1):
				var platform: Rect2 = world.level.platforms[i]
				var distance: float = platform.end.x-hero.position.x
				if distance < 40 and distance > -5 and hero.is_on_floor() and jumped_at != i:
					Input.action_press("jump")
					jumped_at = i
					jump_frames = 16
			# Jump over the moth on platform four.
			if index >= 3 and hero.is_on_floor() and world.enemy_position.x-hero.position.x < 105 and world.enemy_position.x-hero.position.x > 45:
				Input.action_press("jump")
				jump_frames = 16
			if jump_frames > 0:
				jump_frames -= 1
				if jump_frames == 0: Input.action_release("jump")
			await get_tree().physics_frame
		Input.action_release("right")
		Input.action_release("jump")
		if not finished and not world.is_dead:
			failures.append("Level %d timed out at %s, receiver %s" % [index,str(world.hero.position),str(world.receiver_on)])
		print("TRAVERSED ",index," finished=",finished," fireflies=",world.collected.size())
		game.show_map()
		await get_tree().process_frame
	Save.data = previous
	Save.write()
	game.queue_free()
	await get_tree().create_timer(1).timeout
	Audio.shutdown()
	await get_tree().process_frame
	await get_tree().process_frame
	print("TRAVERSAL_RESULT ",JSON.stringify({"levels":10,"failures":failures}))
	get_tree().quit.call_deferred(0 if failures.is_empty() else 1)
