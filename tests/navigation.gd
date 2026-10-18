extends Node
## Exercise actual menu pointer events and interruptions during asynchronous loading.
var game: Node
var failures: Array[String] = []
var checks := 0
var previous: Dictionary

func _ready() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL ", message)

func menu_button(prefix: String) -> Button:
	for item in game.ui.find_children("*", "Button", true, false):
		if item.text.begins_with(prefix):
			return item
	return null

func click(item: Button) -> void:
	if item == null:
		check(false, "Expected menu button is present")
		return
	var point := item.get_global_rect().get_center()
	var dispatch := {"completed": false}
	item.pressed.connect(func(): dispatch.completed = true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		get_tree().root.push_input(event, true)
		await get_tree().process_frame
	await get_tree().process_frame
	check(dispatch.completed, "Button signal dispatch completes before its menu is removed")

func run() -> void:
	previous = Save.data.duplicate(true)
	Save.data = Save.defaults()
	game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await click(menu_button("PLAY"))
	check(game.state == "map", "Pointer click opens the map")
	await click(menu_button("1"))
	check(game.state == "playing" and is_instance_valid(game.world), "Map pointer click finishes loading")
	game.world.hero.reset_at(game.world.point(game.world.level.checkpoints[1]) + Vector2(0,-1))
	for i in range(5): await get_tree().physics_frame
	game.show_home()
	await click(menu_button("CONTINUE"))
	check(game.state == "playing" and game.world.checkpoint_on, "Continue pointer click restores saved checkpoint")
	check(Save.data.resume.get("checkpoint",false), "Continue preserves the checkpoint in device storage")
	game.show_home()
	await click(menu_button("CONTINUE"))
	check(game.world.checkpoint_on and game.world.hero.position.distance_to(game.world.point(game.world.level.checkpoints[1])) < 10, "A second Continue returns to the same checkpoint")
	game.show_pause()
	await click(menu_button("RESUME"))
	check(game.state == "playing" and game.world.can_process(), "Resume pointer click enables gameplay")
	# A phone can lose focus while the loading frame is being presented.
	game.start_level(2)
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	await get_tree().process_frame
	check(game.state == "pause" and not game.world.can_process(), "Focus loss during loading leaves the new level paused")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await click(menu_button("RESUME"))
	check(game.state == "playing" and game.world.can_process(), "Loading interruption recovers through Resume")
	Save.data = previous
	Save.write()
	game.queue_free()
	await get_tree().process_frame
	Audio.shutdown()
	await get_tree().process_frame
	print("NAVIGATION_RESULT ", JSON.stringify({"checks": checks, "failures": failures}))
	get_tree().quit.call_deferred(0 if failures.is_empty() else 1)
