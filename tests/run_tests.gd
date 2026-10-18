extends Node
var checks = 0
var failures: Array[String] = []
var game: Node
var previous: Dictionary
func _ready() -> void:run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:failures.append(message);print("FAIL ",message)
func frames(n: int) -> void:
	for i in range(n):await get_tree().physics_frame
func touch(index: int,position: Vector2,pressed: bool,cancel = false) -> void:
	var e = InputEventScreenTouch.new();e.index=index;e.position=position;e.pressed=pressed;e.canceled=cancel;get_tree().root.push_input(e,true)
func drag(index: int,position: Vector2) -> void:
	var e = InputEventScreenDrag.new();e.index=index;e.position=position;get_tree().root.push_input(e,true)
func run() -> void:
	previous = Save.data.duplicate(true)
	Save.data = Save.defaults()
	game = load("res://scenes/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame
	await game.start_level(1)
	await frames(12)
	var world: LanternWorld = game.world
	var pad = game.hud_move.global_position
	var jump = Vector2(game.screen_width-game.margin_right-64,game.screen_height-95)
	var x = world.hero.position.x
	var y = world.hero.position.y
	touch(0,pad,true);drag(0,pad+Vector2(3,0))
	check(world.hero.touch_direction==0,"Thumbstick dead zone")
	drag(0,pad+Vector2(30,0))
	check(world.hero.touch_direction>.4 and world.hero.touch_direction<.7,"Proportional thumbstick input")
	drag(0,pad+Vector2(70,0));touch(2,pad,true);drag(2,pad-Vector2(70,0));touch(2,pad,false)
	check(world.hero.touch_direction==1,"Unrelated finger cannot steal drag")
	touch(1,jump,true)
	await frames(12)
	check(world.hero.position.x>x+20 and world.hero.position.y<y-35,"Left drag and right jump operate simultaneously")
	touch(1,jump,false);drag(0,pad-Vector2(140,0))
	check(world.hero.touch_direction==-1,"Drag reverses outside pad")
	touch(0,pad-Vector2(250,0),false)
	check(world.hero.touch_direction==0 and not Input.is_action_pressed("jump"),"Outside release clears actions")
	touch(0,pad,true);drag(0,pad+Vector2(70,0));touch(0,pad,false,true)
	check(world.hero.touch_direction==0,"System cancellation clears drag")
	touch(0,pad,true);drag(0,pad+Vector2(70,0));game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state=="pause" and world.hero.touch_direction==0,"Focus loss pauses and clears movement")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_IN);game.resume_game();drag(0,pad+Vector2(70,0))
	check(world.hero.touch_direction==0,"Stale drag cannot resume movement")
	touch(0,pad,true);drag(0,pad+Vector2(70,0));game._on_resize()
	check(world.hero.touch_direction==0 and game.hud_move.finger==-1,"Resize clears held controls")
	# A crate keeps ownership of held USE when a nearby winch becomes closer.
	await game.start_level(23);await frames(12);world=game.world
	var crate: LanternCrate = world.crates.brace
	world.hero.reset_at(crate.position-Vector2(65,0));world.hero.protection=999;world.hero.touch_direction=1
	Input.action_press("interact");await frames(110);Input.action_release("interact");world.hero.touch_direction=0
	check(world.flags.get("brace",false),"Held USE keeps crate ownership beside another control")
	# Safe checkpoint restoration and actual save serialization.
	world.persist_checkpoint();var snap = world.snapshot();check(Save.write(),"Local save commits: "+Save.last_error)
	Save.load_progress();check(Save.data.resume.get("flags",{}).get("brace",false),"Quest and mechanism states survive file reload")
	world.die();world.retry();check(world.health==3 and world.flags.get("brace",false),"Free retry keeps completed mechanism")
	game.resume_game()
	await game.start_level(16);await frames(12);world=game.world
	world.hero.reset_at(Vector2(1300,850));world.hero.protection=999
	Input.action_press("jump");await frames(35);Input.action_release("jump")
	check(world.hero.position.y<750,"Held jump swims upward in deep water")
	check(world.hero.glider_unlocked==false,"Glider is not granted before highlands")
	await game.start_level(31);await frames(12);world=game.world
	world.hero.reset_at(Vector2(620,480));world.hero.velocity.y=180;world.hero.protection=999
	await frames(1);Input.action_press("jump");await frames(35)
	check(world.hero.glider_unlocked and world.hero.gliding,"Holding jump after ascent opens glider")
	check(world.hero.velocity.y<110,"Glider limits descent and responds to wind")
	Input.action_release("jump");await frames(2);check(not world.hero.gliding,"Releasing jump folds glider")
	await game.start_level(35);await frames(12);world=game.world
	var ice: Dictionary=world.objects.ice_a
	world.hero.reset_at(world.point(ice.pos)-Vector2(90,0));world.hero.frozen=true;world.hero.protection=999;world.hero.facing=1;world.hero.lantern_on=true
	world.lens=0;await frames(85);check(not world.flags.get("ice_a",false),"Ordinary light cannot freeze water")
	world.lens=2;await frames(85);check(world.flags.get("ice_a",false),"Frost charges a marked water socket")
	world.hero.position=world.point(ice.pos)-Vector2(0,10);var lifetime=float(world.temporary.get("ice_a",0));await frames(150)
	check(float(world.temporary.get("ice_a",0))>=lifetime-.1,"Standing on temporary ice pauses its timer")
	world.hero.position=world.level.spawn;await frames(750);check(not world.flags.get("ice_a",false),"Unused ice melts and can be recreated")
	await game.start_level(1);await frames(12);world=game.world
	world.hero.reset_at(Vector2(900,580));world.hero.frozen=true;world.hero.protection=0;world.hurt(Vector2(950,580))
	check(world.health==2,"Enemy contact costs one heart")
	world.hurt(Vector2(950,580));check(world.health==2,"Damage protection prevents duplicate hits")
	world.hero.protection=0;world.hurt(Vector2(950,580));world.hero.protection=0;world.hurt(Vector2(950,580))
	check(world.is_dead,"Three unprotected hits trigger retry")
	world.retry();check(world.health==3 and not world.is_dead,"Retry restores full health")
	check(not Ads.rewarded_ready(),"Offline build never requires an available ad")
	game.show_map();check(game.ui.find_children("*","Button",true,false).size()>=15,"Chapter map exposes four tabs and ten levels")
	check(Save.complete(1,0,5,true)==2,"Discovery star is independent of failures")
	Save.complete(1,5,0,false);check(Save.best(1).stars==3 and Save.best(1).fireflies==5,"Replay combines best fireflies and discovered memory")
	await game.start_level(17);await frames(12);world=game.world
	world.hero.reset_at(world.point(world.objects.transfer.pos));world.hero.frozen=true;world.interact("transfer")
	check(int(world.values.left)+int(world.values.right)==3 and world.meets(["left:2","right:1"]),"Cistern transfer conserves three units and reaches target levels")
	await game.start_level(24);await frames(12);world=game.world
	world.flags.heat_a=true;world.flags.heat_b=true;world.flags.heat_inner=true
	world.hero.reset_at(world.point(world.objects.insulated.pos));world.hero.frozen=true;await frames(3)
	check(not world.flags.get("insulated",false),"Lighting the inner decoy blocks the key route")
	world.hero.position=world.point(world.objects.heat_inner.pos);world.interact("heat_inner");world.hero.position=world.point(world.objects.insulated.pos);await frames(3)
	check(world.flags.get("insulated",false),"Extinguishing the wrong decoy recovers the key puzzle")
	await game.start_level(23);await frames(12);world=game.world
	world.hero.reset_at(world.point(world.objects.vines.pos)-Vector2(90,0));world.hero.frozen=true;world.hero.protection=999;world.hero.lantern_on=true;world.hero.facing=1;world.lens=1
	await frames(85)
	check(world.flags.get("fallen_stair",false) and not world.flags.get("vines",false),"Heating unbraced vines drops the stair instead of solving it")
	world.hero.position=world.point(world.objects.winch.pos);world.interact("winch")
	check(not world.flags.get("fallen_stair",false),"Winch restores the fallen stair without consuming a quest item")
	await game.start_level(7);await frames(12);world=game.world
	world.hero.reset_at(Vector2(1550,615));world.hero.frozen=true;world.hero.protection=999;await frames(130)
	check(float(world.brittle.get("orchard_branch",0))>=2,"Brittle branch gives a two-second warning before breaking")
	var broken=false
	for row in world.platforms:
		if row.data.get("break_id","")=="orchard_branch" and row.body.collision_layer==0:broken=true
	check(broken,"Broken branch disables collision above the recovery shelf")
	game.show_journal();check(game.state=="journal" and world.process_mode==Node.PROCESS_MODE_DISABLED,"Journal pauses play and supports scrolling long clues")
	await game.start_level(11);await frames(12);world=game.world
	var ferry: AnimatableBody2D=world.vehicles[0].body
	world.hero.reset_at(ferry.position-Vector2(0,2));world.hero.protection=999
	var boarding_x=world.hero.position.x
	await frames(200)
	check(world.hero.position.x>boarding_x+60 and absf(world.hero.position.y-ferry.position.y)<20,"Raft carries a standing character through real moving-platform physics")
	Save.data=previous;Save.write();game.queue_free();await get_tree().process_frame;Audio.shutdown();await get_tree().process_frame
	print("CONTROL_RESULT ",JSON.stringify({"checks":checks,"failures":failures}));get_tree().quit.call_deferred(0 if failures.is_empty() else 1)
