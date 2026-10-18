extends Node2D
## Screen flow and input orchestration. Gameplay rules live in LanternWorld.
const GOLD = Color(1,.79,.36)
const IVORY = Color(.98,.95,.85)
const MUTED = Color(.65,.76,.78)
const SERIF = preload("res://assets/fonts/Story.ttf")
const SANS = preload("res://assets/fonts/Interface.ttf")
const BACKGROUNDS = [preload("res://assets/art/forest.png"),preload("res://assets/art/world-0.png"),preload("res://assets/art/world-1.png")]
var state := "home"
var world: LanternWorld
var background: TextureRect
var background_layer: CanvasLayer
var ui_layer: CanvasLayer
var ui: Control
var overlay: Control
var menu_effects: LanternEffects
var hud_count: Label
var hud_lantern: LanternTouchControl
var hud_move: LanternDragControl
var status_label: Label
var notification_label: Label
var notice_remaining := 0.0
var settings_return := "home"
var busy := false
var completing := false
var result_stars := 0
var result_flies := 0
var saved_flash := 0.0
var focused := true
var pending_reward := ""
var reward_token := ""
var capture_mode := ""
var screen_width := 1280.0
var screen_height := 720.0
var margin_left := 30.0
var margin_right := 30.0
var modal_controls: Array[Control] = []
var result_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_input()
	background_layer = CanvasLayer.new()
	background_layer.layer = -20
	add_child(background_layer)
	background = TextureRect.new()
	background.texture = BACKGROUNDS[0]
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(background)
	menu_effects = LanternEffects.new()
	menu_effects.extent = 1400
	background_layer.add_child(menu_effects)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	get_viewport().size_changed.connect(_on_resize)
	Save.save_failed.connect(func(): toast("Progress could not be saved. Check device storage."))
	Ads.reward_earned.connect(_on_reward)
	Ads.closed.connect(_on_ad_closed)
	refresh_size()
	show_home()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_mode = arg.trim_prefix("--capture=")
	if not capture_mode.is_empty():
		capture.call_deferred()

func setup_input() -> void:
	var keys := {"left": [KEY_A,KEY_LEFT], "right": [KEY_D,KEY_RIGHT], "jump": [KEY_SPACE,KEY_W,KEY_UP], "lantern": [KEY_E,KEY_L], "pause": [KEY_ESCAPE,KEY_P]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)

func refresh_size() -> void:
	var size := get_viewport_rect().size
	screen_width = size.x
	screen_height = size.y
	background.size = size
	margin_left = 30
	margin_right = 30
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var physical := Vector2(DisplayServer.window_get_size())
		if safe.size.x > 0 and physical.x > 0:
			margin_left = maxf(30,safe.position.x / physical.x * size.x + 12)
			margin_right = maxf(30,(physical.x-safe.end.x) / physical.x * size.x + 12)

func _on_resize() -> void:
	refresh_size()
	if busy:
		return
	match state:
		"home": show_home()
		"map": show_map()
		"playing": show_hud()
		"pause": show_pause()
		"dead": show_death()
		"results": show_results(result_stars,result_flies)
		"settings": show_settings(settings_return)
		"guide": show_guide()

func clear_ui() -> void:
	release_controls()
	if is_instance_valid(ui):
		# A menu transition can run inside a child's pressed signal. Keep the
		# emitter alive until dispatch completes, but retire its input immediately.
		ui.hide()
		ui.process_mode = Node.PROCESS_MODE_DISABLED
		ui.queue_free()
	ui = Control.new()
	ui.size = Vector2(screen_width,screen_height)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui)
	hud_count = null
	hud_lantern = null
	hud_move = null
	status_label = null
	notification_label = null
	modal_controls.clear()

func remove_world() -> void:
	if is_instance_valid(result_timer):
		result_timer.queue_free()
	result_timer = null
	if is_instance_valid(world):
		world.free()
	world = null
	completing = false
	Ads.invalidate()
	reward_token = ""

func label(text: String, rect: Rect2, size := 22, color := IVORY, parent: Node = null, serif := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var item := Label.new()
	item.text = text
	item.position = rect.position
	item.size = rect.size
	item.add_theme_font_override("font",SERIF if serif else SANS)
	item.add_theme_font_size_override("font_size",size)
	item.add_theme_color_override("font_color",color)
	item.add_theme_color_override("font_shadow_color",Color(0,0,0,.65))
	item.add_theme_constant_override("shadow_offset_y",2)
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else ui).add_child(item)
	return item

func style(fill: Color, border: Color, radius := 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func button(text: String, rect: Rect2, callback: Callable, primary := false, parent: Node = null, circle := false) -> Button:
	var item := Button.new()
	item.text = text
	var hit_size := Vector2(maxf(64,rect.size.x),maxf(64,rect.size.y))
	item.position = rect.position - (hit_size-rect.size)/2
	item.size = hit_size
	item.add_theme_font_override("font",SERIF if primary else SANS)
	item.add_theme_font_size_override("font_size",25 if primary else 21)
	item.add_theme_color_override("font_color",Color(.12,.085,.025) if primary else IVORY)
	item.add_theme_color_override("font_hover_color",Color(.12,.085,.025) if primary else Color(1,.89,.61))
	item.add_theme_color_override("font_pressed_color",Color(.12,.085,.025) if primary else GOLD)
	item.add_theme_stylebox_override("normal",style(Color(1,.73,.22) if primary else Color(.035,.08,.11,.9),Color(1,.87,.52) if primary else Color(.54,.62,.62,.7),50 if circle else 16))
	item.add_theme_stylebox_override("hover",style(Color(1,.84,.4) if primary else Color(.1,.19,.22,.97),GOLD,50 if circle else 16))
	item.add_theme_stylebox_override("pressed",style(Color(.9,.59,.14) if primary else Color(.16,.24,.25),GOLD,50 if circle else 16))
	item.add_theme_stylebox_override("disabled",style(Color(.045,.08,.1,.8),Color(.3,.38,.4,.5),50 if circle else 16))
	item.add_theme_stylebox_override("focus",style(Color(0,0,0,0),Color(1,.91,.64),50 if circle else 16))
	item.pressed.connect(func(): Audio.cue("tap"); callback.call())
	(parent if parent != null else ui).add_child(item)
	return item

func image_rect(texture: Texture2D, rect: Rect2, parent: Node = null) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.position = rect.position
	image.size = rect.size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else ui).add_child(image)
	return image

func shade(alpha: float) -> void:
	var dim := ColorRect.new()
	dim.size = Vector2(screen_width,screen_height)
	dim.color = Color(.005,.018,.025,alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dim)

func animated_hero(point: Vector2, scale_factor: float, animation := "idle", parent: Node = null) -> AnimatedSprite2D:
	var actor := AnimatedSprite2D.new()
	actor.sprite_frames = LanternHero.make_frames()
	actor.position = point
	actor.scale = Vector2.ONE * scale_factor * .5
	actor.play(animation)
	(parent if parent != null else ui).add_child(actor)
	return actor

func show_home() -> void:
	state = "home"
	remove_world()
	clear_ui()
	background.texture = BACKGROUNDS[0]
	background.modulate = Color.WHITE
	menu_effects.visible = true
	shade(.08)
	var center := screen_width * .67
	label("LITTLE\nLANTERN",Rect2(center-270,155,540,210),68,GOLD,null,true,HORIZONTAL_ALIGNMENT_CENTER)
	label("Find your light. Bring them home.",Rect2(center-290,365,580,40),21,IVORY,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	button("CONTINUE  ›" if not Save.data.resume.is_empty() else "PLAY  ›",Rect2(center-170,440,340,68),func():
		if not Save.data.resume.is_empty():
			start_level(int(Save.data.resume.level),true)
		else:
			show_map()
	,true)
	button("World map",Rect2(center-170,525,160,52),show_map)
	button("How to play",Rect2(center+10,525,160,52),show_guide)
	image_rect(preload("res://assets/art/platform.png"),Rect2(screen_width*.09,527,400,150))
	animated_hero(Vector2(screen_width*.25,457),2.0)
	button("⚙",Rect2(margin_left,screen_height-85,60,60),func(): show_settings("home"),false,null,true)
	button("♫",Rect2(margin_left+76,screen_height-85,60,60),toggle_music,false,null,true)
	label("An offline adventure",Rect2(screen_width-330,screen_height-64,290,32),16,MUTED,null,false,HORIZONTAL_ALIGNMENT_RIGHT)
	if not Save.last_error.is_empty():
		toast("Your progress is in memory. Device storage is unavailable.")

func show_map() -> void:
	state = "map"
	remove_world()
	clear_ui()
	menu_effects.visible = true
	background.texture = BACKGROUNDS[0]
	background.modulate = Color(.8,.88,.92)
	shade(.25)
	button("‹",Rect2(margin_left,28,62,56),show_home,false,null,true)
	label("Whispering Woods",Rect2(200,35,screen_width-400,55),38,GOLD,null,true,HORIZONTAL_ALIGNMENT_CENTER)
	label("A journey through forest, cavern and forgotten ruins",Rect2(200,99,screen_width-400,36),18,IVORY,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	var left := maxf(130,margin_left+85)
	var step := (screen_width - left - margin_right - 120) / 4.0
	var points: Array[Vector2] = []
	for i in range(10):
		var col := i if i < 5 else 9-i
		var point := Vector2(left+col*step,280+sin(i*.95)*40 if i < 5 else 490+cos(i)*25)
		points.append(point)
	for i in range(9):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i+1]
		var count := int(a.distance_to(b)/14)
		for j in range(1,count):
			var dot := ColorRect.new()
			dot.position = a.lerp(b,float(j)/count) - Vector2(2,2)
			dot.size = Vector2(4,4)
			dot.color = Color(1,.81,.41,.8 if Save.unlocked(i+2) else .22)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ui.add_child(dot)
	for i in range(10):
		var index := i+1
		var unlocked := Save.unlocked(index)
		var pos: Vector2 = points[i]
		var best := Save.best(index)
		var node := button(str(index),Rect2(pos-Vector2(34,34),Vector2(68,68)),func(): start_level(index),unlocked,null,true)
		node.disabled = not unlocked
		node.tooltip_text = LanternLevels.TITLES[i] if unlocked else "Complete level %d to unlock" % i
		label("★".repeat(int(best.stars)) if best.completed else ("READY" if unlocked else "LOCKED"),Rect2(pos.x-85,pos.y+41,170,30),17,GOLD if unlocked else MUTED,null,false,HORIZONTAL_ALIGNMENT_CENTER)
		if unlocked and not best.completed:
			animated_hero(pos-Vector2(0,82),.54)
	label("FOREST  1–4       •       CAVERN  5–7       •       RUINS  8–10",Rect2(140,screen_height-88,screen_width-280,35),18,IVORY,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	button("How to play",Rect2(screen_width-220-margin_right,screen_height-75,220,50),show_guide)

func start_level(index: int, restore := false) -> void:
	if busy:
		return
	busy = true
	state = "loading"
	clear_ui()
	shade(.65)
	label("Lighting the way…",Rect2(0,300,screen_width,75),34,GOLD,null,true,HORIZONTAL_ALIGNMENT_CENTER)
	await get_tree().process_frame
	remove_world()
	world = LanternWorld.new()
	world.name = "Adventure"
	add_child(world)
	world.setup(index,Save.data.resume if restore else {})
	world.status_changed.connect(update_hud)
	world.died.connect(show_death)
	world.finished.connect(level_complete)
	world.checkpoint_saved.connect(func(): toast("Checkpoint saved"))
	world.message_requested.connect(toast)
	background.texture = BACKGROUNDS[world.level.theme]
	background.modulate = Color(.65,.76,.84)
	menu_effects.visible = false
	state = "playing"
	busy = false
	completing = false
	show_hud()
	if index <= 2 and not Save.best(index).completed:
		toast("Drag the left pad to move. Tap ↑ to jump and ☼ for light.",6)
	world.persist_checkpoint()
	if not focused:
		show_pause()

func show_hud() -> void:
	clear_ui()
	var plate := Panel.new()
	plate.position = Vector2(margin_left,25)
	plate.size = Vector2(143,48)
	plate.add_theme_stylebox_override("panel",style(Color(.015,.04,.06,.8),Color(.65,.55,.32,.5),18))
	ui.add_child(plate)
	hud_count = label("",Rect2(margin_left+16,28,125,42),26,GOLD)
	label("—  Level %d  —" % world.level.id,Rect2(screen_width/2-210,26,420,42),25,IVORY,null,true,HORIZONTAL_ALIGNMENT_CENTER)
	label(world.level.title,Rect2(screen_width/2-260,69,520,28),16,MUTED,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	button("?",Rect2(screen_width-margin_right-136,25,55,50),hint_pressed,false,null,true)
	button("Ⅱ",Rect2(screen_width-margin_right-61,25,58,50),show_pause,false,null,true)
	hud_move = LanternDragControl.new()
	hud_move.position = Vector2(margin_left+100,screen_height-95)
	hud_move.axis_changed.connect(func(value: float):
		if is_instance_valid(world): world.hero.touch_direction = value
	)
	ui.add_child(hud_move)
	add_touch("jump","↑",Vector2(screen_width-margin_right-64,screen_height-95),50)
	hud_lantern = add_touch("lantern","☼",Vector2(screen_width-margin_right-180,screen_height-85))
	label("DRAG TO MOVE",Rect2(margin_left+20,screen_height-25,160,18),10,MUTED,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	label("JUMP",Rect2(screen_width-margin_right-106,screen_height-26,84,18),10,MUTED,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	label("LIGHT",Rect2(screen_width-margin_right-222,screen_height-26,84,18),10,GOLD,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	status_label = label("",Rect2(screen_width/2-250,screen_height-61,500,32),17,MUTED,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	notification_label = label("",Rect2(screen_width/2-410,137,820,45),22,IVORY,null,true,HORIZONTAL_ALIGNMENT_CENTER)
	update_hud()

func add_touch(action: String, glyph: String, point: Vector2, radius := 39.0) -> LanternTouchControl:
	var control := LanternTouchControl.new()
	control.action = action
	control.glyph = glyph
	control.button_radius = radius
	control.position = point
	ui.add_child(control)
	return control

func update_hud() -> void:
	if is_instance_valid(hud_count) and is_instance_valid(world):
		hud_count.text = "☼  %d / 5" % world.collected.size()

func toast(text: String, duration := 3.0) -> void:
	if not is_instance_valid(notification_label):
		if not is_instance_valid(ui):
			return
		notification_label = label("",Rect2(screen_width/2-410,137,820,45),20,IVORY,null,true,HORIZONTAL_ALIGNMENT_CENTER)
	notification_label.text = text
	notice_remaining = duration

func modal(title: String, subtitle: String, height := 390.0) -> Panel:
	clear_ui()
	shade(.6)
	var panel := Panel.new()
	panel.position = Vector2((screen_width-560)/2,(screen_height-height)/2)
	panel.size = Vector2(560,height)
	panel.add_theme_stylebox_override("panel",style(Color(.018,.045,.062,.97),Color(.86,.69,.37),26))
	ui.add_child(panel)
	label(title,Rect2(25,24,510,60),36,GOLD,panel,true,HORIZONTAL_ALIGNMENT_CENTER)
	label(subtitle,Rect2(25,89,510,50),18,IVORY,panel,false,HORIZONTAL_ALIGNMENT_CENTER)
	return panel

func show_pause() -> void:
	if not is_instance_valid(world):
		return
	state = "pause"
	world.process_mode = Node.PROCESS_MODE_DISABLED
	world.persist_checkpoint()
	var panel := modal("A moment of quiet", "Your checkpoint is saved.",470)
	button("RESUME  ›",Rect2(100,155,360,61),resume_game,true,panel)
	button("Restart level",Rect2(100,234,360,53),func(): confirm_restart(),false,panel)
	button("Settings",Rect2(100,303,170,53),func(): show_settings("pause"),false,panel)
	button("World map",Rect2(290,303,170,53),confirm_leave,false,panel)
	label("Progress since the checkpoint resets on leaving.",Rect2(30,385,500,40),15,MUTED,panel,false,HORIZONTAL_ALIGNMENT_CENTER)

func resume_game() -> void:
	if not focused:
		return
	state = "playing"
	world.process_mode = Node.PROCESS_MODE_INHERIT
	release_controls()
	show_hud()

func confirm_restart() -> void:
	state = "confirm"
	var panel := modal("Restart this level?","This attempt and its collected fireflies will reset.",320)
	button("RESTART",Rect2(100,160,360,58),func(): start_level(world.level.id),true,panel)
	button("Keep playing",Rect2(100,235,360,48),show_pause,false,panel)

func confirm_leave() -> void:
	state = "confirm"
	var panel := modal("Return to the map?","Your checkpoint stays saved. This attempt will pause.",320)
	button("WORLD MAP",Rect2(100,160,360,58),show_map,true,panel)
	button("Stay here",Rect2(100,235,360,48),show_pause,false,panel)

func show_death() -> void:
	state = "dead"
	release_controls()
	var panel := modal("Try again?","Return to your checkpoint and keep exploring.",385)
	button("RETRY  ↻",Rect2(100,155,360,62),func():
		world.retry()
		state = "playing"
		show_hud()
	,true,panel)
	if Ads.rewarded_ready() and not world.revived:
		button("Watch ad · Revive",Rect2(100,236,360,52),func(): request_reward("revive"),false,panel)
	else:
		label("Free retries. No lives to wait for.",Rect2(60,238,440,40),17,MUTED,panel,false,HORIZONTAL_ALIGNMENT_CENTER)
	button("World map",Rect2(177,310,206,48),show_map,false,panel)

func level_complete(fireflies: int, deaths_count: int) -> void:
	if completing:
		return
	completing = true
	result_stars = Save.complete(world.level.id,fireflies,deaths_count)
	result_flies = fireflies
	Ads.completed_since_ad += 1
	state = "results"
	release_controls()
	var finished_attempt := world.attempt_token
	result_timer = Timer.new()
	result_timer.one_shot = true
	result_timer.wait_time = .7
	add_child(result_timer)
	result_timer.timeout.connect(func():
		if state == "results" and is_instance_valid(world) and world.attempt_token == finished_attempt:
			show_results(result_stars,result_flies)
		if is_instance_valid(result_timer):
			result_timer.queue_free()
		result_timer = null
	)
	result_timer.start()

func show_results(stars: int, flies: int) -> void:
	state = "results"
	result_stars = stars
	result_flies = flies
	var final: bool = world.level.id == 10
	var panel := modal("You brought them home!" if final else "Level complete!","Every little light makes a difference.",470)
	label("★".repeat(stars) + "☆".repeat(3-stars),Rect2(40,135,480,80),55,GOLD,panel,false,HORIZONTAL_ALIGNMENT_CENTER)
	label("☼  %d / 5 fireflies" % flies,Rect2(80,219,400,37),23,IVORY,panel,false,HORIZONTAL_ALIGNMENT_CENTER)
	button("WORLD MAP" if final else "NEXT LEVEL  ›",Rect2(100,282,360,64),func(): transition_after_results(final),true,panel)
	button("Replay",Rect2(100,367,170,51),func(): start_level(world.level.id),false,panel)
	button("Map",Rect2(290,367,170,51),func(): transition_after_results(true),false,panel)

func transition_after_results(to_map: bool) -> void:
	var next := int(world.level.id) + 1
	if Ads.try_interstitial():
		pending_reward = "map" if to_map else "next:" + str(next)
		world.process_mode = Node.PROCESS_MODE_DISABLED
		Audio.suspend(true)
		return
	if to_map:
		show_map()
	else:
		start_level(next)

func show_settings(return_to: String) -> void:
	settings_return = return_to
	state = "settings"
	if is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
	clear_ui()
	shade(.68)
	var panel := Panel.new()
	panel.position = Vector2((screen_width-700)/2,55)
	panel.size = Vector2(700,610)
	panel.add_theme_stylebox_override("panel",style(Color(.018,.045,.062,.98),Color(.66,.6,.42),24))
	ui.add_child(panel)
	label("Settings",Rect2(25,16,650,60),36,GOLD,panel,true,HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(2):
		var key := "music" if i == 0 else "effects"
		label("Music" if i == 0 else "Sound effects",Rect2(45,100+i*85,240,40),21,IVORY,panel)
		var slider := HSlider.new()
		slider.position = Vector2(300,95+i*85)
		slider.size = Vector2(340,64)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = .05
		slider.value = Save.data.settings[key]
		slider.value_changed.connect(func(value: float):
			Save.set_setting(key,value)
			Audio.refresh()
		)
		panel.add_child(slider)
	var toggles := [["Vibration","vibration"],["Reduced effects","reduced_effects"]]
	for i in range(2):
		var toggle := CheckButton.new()
		toggle.position = Vector2(45,280+i*62)
		toggle.size = Vector2(600,60)
		toggle.text = toggles[i][0]
		toggle.add_theme_font_override("font",SANS)
		toggle.add_theme_font_size_override("font_size",21)
		var key: String = toggles[i][1]
		toggle.button_pressed = Save.data.settings[key]
		toggle.toggled.connect(func(value: bool): Save.set_setting(key,value))
		panel.add_child(toggle)
	if Ads.bridge != null and Ads.bridge.has_method("privacy_options_required") and bool(Ads.bridge.call("privacy_options_required")):
		button("Privacy options",Rect2(45,410,295,52),func(): Ads.bridge.call("show_privacy_options"),false,panel)
	else:
		button("About and privacy",Rect2(45,410,295,52),show_privacy,false,panel)
	button("Reset progress",Rect2(360,410,295,52),confirm_reset,false,panel)
	button("DONE",Rect2(210,505,280,60),close_settings,true,panel)

func close_settings() -> void:
	if settings_return == "pause" and is_instance_valid(world):
		show_pause()
	else:
		show_home()

func confirm_reset() -> void:
	state = "confirm"
	var panel := modal("Reset all progress?","All levels, stars and checkpoints will be cleared.",330)
	button("RESET PROGRESS",Rect2(100,160,360,58),func():
		Save.reset_progress()
		show_home()
	,true,panel)
	button("Cancel",Rect2(100,240,360,48),func(): show_settings(settings_return),false,panel)

func show_privacy() -> void:
	state = "privacy"
	var panel := modal("About Little Lantern","An offline adventure · Version " + str(ProjectSettings.get_setting("application/config/version")),465)
	var body := label("Progress and settings are stored on this device.\nNo account or developer server is used.\nThis build does not request advertising data.\nClearing app data removes your progress.\n\nArt created for Little Lantern.\nGodot Engine · DejaVu fonts",Rect2(40,143,480,210),18,IVORY,panel,false,HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("BACK",Rect2(65,375,205,56),func(): show_settings(settings_return),true,panel)
	button("Licenses",Rect2(290,375,205,56),show_licenses,false,panel)

func show_licenses() -> void:
	state = "licenses"
	var panel := modal("Open source notices","Godot Engine and DejaVu fonts",610)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(35,145)
	scroll.size = Vector2(490,340)
	panel.add_child(scroll)
	var text := RichTextLabel.new()
	text.custom_minimum_size = Vector2(466,0)
	text.fit_content = true
	text.scroll_active = false
	text.add_theme_font_override("normal_font",SANS)
	text.add_theme_font_size_override("normal_font_size",15)
	text.text = FileAccess.get_file_as_string("res://assets/licenses/GODOT.txt") + "\n\nDEJAVU FONTS\n\n" + FileAccess.get_file_as_string("res://assets/fonts/LICENSE.txt")
	scroll.add_child(text)
	button("BACK",Rect2(130,520,300,56),show_privacy,true,panel)

func show_guide() -> void:
	state = "guide"
	clear_ui()
	shade(.7)
	label("Carry a little light",Rect2(0,60,screen_width,65),42,GOLD,null,true,HORIZONTAL_ALIGNMENT_CENTER)
	var lines := ["MOVE  ·  Drag the left thumb pad left or right. Release to stop.","JUMP  ·  Tap ↑. Hold a little longer to jump higher.","LANTERN  ·  Tap ☼ to toggle your light. Face a hidden path to reveal it.","SUN RECEIVERS  ·  Shine light on a sun disc to open the exit gate.","FIREFLIES  ·  Rescue all five. Finish without a fall for three stars.","CHECKPOINTS  ·  Glowing shrines save your place. Retry is always free.","MOTHS  ·  Jump over them, or switch your lantern off to avoid attracting them."]
	for i in range(lines.size()):
		label(lines[i],Rect2(120,166+i*53,screen_width-240,48),19,IVORY)
	label("Keyboard: A / D or arrows · Space to jump · E for light · Esc to pause",Rect2(70,555,screen_width-140,35),16,MUTED,null,false,HORIZONTAL_ALIGNMENT_CENTER)
	button("LET’S EXPLORE",Rect2(screen_width/2-180,615,360,62),show_map,true)

func toggle_music() -> void:
	Save.set_setting("music",0.55 if float(Save.data.settings.music) < .01 else 0.0)
	Audio.refresh()

func hint_pressed() -> void:
	if Ads.rewarded_ready():
		state = "hint"
		world.process_mode = Node.PROCESS_MODE_DISABLED
		var panel := modal("Need a little light?","Watch an ad to highlight the next puzzle clue.",330)
		button("WATCH AD · HINT",Rect2(100,160,360,58),func(): request_reward("hint"),true,panel)
		button("Keep exploring",Rect2(100,238,360,48),resume_game,false,panel)
	else:
		world.show_hint()

func request_reward(placement: String) -> void:
	var token := world.attempt_token + ":" + placement + ":" + str(Time.get_ticks_usec())
	reward_token = token
	pending_reward = placement
	world.process_mode = Node.PROCESS_MODE_DISABLED
	if not Ads.show_rewarded(placement,token):
		pending_reward = ""
		if placement == "revive":
			world.process_mode = Node.PROCESS_MODE_INHERIT
			show_death()
		else: resume_game()
		return
	Audio.suspend(true)

func _on_reward(placement: String, token: String) -> void:
	if not is_instance_valid(world) or token != reward_token or not token.begins_with(world.attempt_token + ":" + placement + ":"):
		return
	# Apply the earned effect before dismissal; do not unpause the world yet.
	if placement == "revive":
		world.revive()
	elif placement == "hint":
		world.hint_time = 8
	pending_reward = "earned:" + placement
	if not Ads.fullscreen_pending:
		pending_reward = ""
		if focused: resume_game()
		else: show_pause()

func _on_ad_closed() -> void:
	Audio.suspend(not focused)
	var outcome := pending_reward
	pending_reward = ""
	if outcome == "map":
		show_map()
	elif outcome.begins_with("next:"):
		start_level(int(outcome.trim_prefix("next:")))
	elif outcome.begins_with("earned:"):
		if focused: resume_game()
		else: show_pause()
	elif outcome == "revive":
		world.process_mode = Node.PROCESS_MODE_INHERIT
		show_death()
	elif is_instance_valid(world):
		if focused: resume_game()
		else: show_pause()

func release_controls() -> void:
	if is_instance_valid(hud_move):
		hud_move.release()
	if is_instance_valid(world):
		world.hero.touch_direction = 0.0
	for action in ["left","right","jump","lantern"]:
		Input.action_release(action)

func _process(delta: float) -> void:
	if state == "playing" and is_instance_valid(world):
		if Input.is_action_just_pressed("lantern"):
			world.hero.lantern_on = not world.hero.lantern_on
			Audio.cue("tap")
		if is_instance_valid(hud_lantern):
			hud_lantern.active_gold = world.hero.lantern_on
		if is_instance_valid(status_label):
			status_label.text = "Light reveals hidden paths" if world.hero.lantern_on else "Your lantern is resting"
	if notice_remaining > 0:
		notice_remaining -= delta
		if notice_remaining <= 0 and is_instance_valid(notification_label):
			notification_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		back()
		get_viewport().set_input_as_handled()

func back() -> void:
	match state:
		"playing": show_pause()
		"pause": resume_game()
		"settings": close_settings()
		"privacy": show_settings(settings_return)
		"licenses": show_privacy()
		"guide", "map": show_home()
		"confirm":
			if is_instance_valid(world): show_pause()
			else: show_settings(settings_return)
		"hint": resume_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		focused = false
		release_controls()
		if state == "playing" and is_instance_valid(world):
			show_pause()
		elif is_instance_valid(world):
			world.persist_checkpoint()
		Audio.suspend(true)
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		focused = true
		if pending_reward.is_empty():
			Audio.suspend(false)

func capture() -> void:
	await get_tree().process_frame
	match capture_mode:
		"map": show_map()
		"level", "puzzle", "results", "pause", "dead", "settings", "bridge", "cave", "ruins":
			await start_level(5 if capture_mode == "cave" else (8 if capture_mode == "ruins" else 1))
			if capture_mode == "puzzle":
				world.hero.position = world.level.receiver - Vector2(130,2)
			elif capture_mode == "bridge":
				world.hero.position = Vector2(world.level.bridge.position.x-80,world.level.bridge.position.y-2)
			elif capture_mode == "results":
				world.hero.position = world.level.exit - Vector2(100,2)
				world.hero.frozen = true
				world.hero.sprite.play("celebrate")
				world.receiver_on = true
				show_results(3,5)
			elif capture_mode == "pause": show_pause()
			elif capture_mode == "dead": world.die()
			elif capture_mode == "settings": show_settings("pause")
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var target := "user://%s.png" % capture_mode
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-file="):
			target = arg.trim_prefix("--capture-file=")
	get_viewport().get_texture().get_image().save_png(target)
	print("CAPTURE_SAVED ", target)
	get_tree().quit()
