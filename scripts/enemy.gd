class_name LanternEnemy
extends Node2D
## Enemies share lifecycle and damage rules, but have different locomotion and tells.
var host: Node
var kind = "crawler"
var home = Vector2.ZERO
var target = Vector2.ZERO
var clock = 0.0
var cycle = 0.0
var mode = "rest"
var boss = false
var span = 75.0
var harmless = false
var definition: Dictionary
const COLORS = {"crawler":Color(.32,.57,.38),"moth":Color(.64,.49,.87),"sentinel":Color(.28,.43,.39),"skimmer":Color(.24,.76,.78),"crab":Color(.57,.46,.36),"eel":Color(.23,.57,.87),"hopper":Color(.87,.37,.13),"wasp":Color(.85,.53,.21),"guard":Color(.39,.32,.30),"stalker":Color(.63,.82,.90),"kite":Color(.47,.68,.88),"wisp":Color(.73,.64,1)}
func configure(data: Dictionary, world: Node) -> void:
	definition = data
	host = world
	kind = str(data.kind)
	home = Vector2(data.pos[0],data.pos[1])
	position = home
	target = home
	boss = bool(data.get("boss",false))
	span = float(data.get("span",75))
	clock = home.x * .001

func tick(delta: float, active: bool) -> void:
	clock += delta
	if not active or not host.meets(definition.get("needs",[])):
		mode = "rest"
		cycle = 0
		queue_redraw()
		return
	var player = host.hero
	var distance = position.distance_to(player.position-Vector2(0,30))
	harmless = false
	if kind in ["moth","eel"]:
		var lure: Vector2 = host.lure_for(kind)
		var desired = home + Vector2(sin(clock)*span,sin(clock*2)*10)
		if lure.is_finite():
			desired = lure-Vector2(0,30)
		elif player.lantern_on and distance < 360:
			desired = player.position-Vector2(0,35)
		position = position.move_toward(desired,(70 if kind=="moth" else 100)*delta)
		mode = "approach" if position.distance_to(home)>60 else "rest"
	elif kind == "crab":
		harmless = player.lantern_on and distance < 230
		position.x = move_toward(position.x,home.x+sin(clock*.7)*span,30*delta) if not harmless else position.x
		mode = "shell" if harmless else "walk"
	elif kind == "crawler":
		position.x = home.x+sin(clock*.75)*span
		mode = "walk"
	elif kind == "hopper":
		cycle = fmod(cycle+delta,3.8)
		mode = "warn" if cycle<.9 else ("attack" if cycle<1.8 else "rest")
		var hop = sin(clampf((cycle-.9)/.9,0,1)*PI)
		position = home+Vector2(sin(clock)*span,-hop*105)
	else:
		cycle += delta
		var lure: Vector2 = host.lure_for(kind)
		var detectable = distance < (650 if boss else 330) and not host.covered(player.position,position)
		if kind == "sentinel": detectable = detectable and player.lantern_on
		if mode == "rest":
			if kind in ["wasp","kite","wisp"]:
				var repel = (90 if host.flags.get("heat_inner",false) else -90) if kind=="wasp" and host.any_heat() else 0
				position = home+Vector2(sin(clock*.8)*span+repel,sin(clock*2)*12)
			if cycle>2.2 and (detectable or lure.is_finite()):
				mode = "warn"
				cycle = 0
				target = lure if lure.is_finite() else player.position-Vector2(0,25)
		elif mode == "warn" and cycle>=1.0:
			mode = "attack"
			cycle = 0
			if kind in ["guard","furnace","stormkeeper"]:
				host.enemy_impact(target,kind)
		elif mode == "attack":
			if kind in ["stag","warden","stalker","kite","wasp","wisp"]:
				position = position.move_toward(target,(520 if boss else 290)*delta)
				if position.distance_to(target)<30: host.enemy_impact(target,kind)
			if kind == "sentinel" and absf(player.position.y-25-position.y)<45 and absf(player.position.x-position.x)<300 and not host.covered(player.position,position):
				host.hurt(position)
			if kind in ["guard","furnace","stormkeeper"] and (player.position-Vector2(0,30)).distance_to(target)<100 and not host.covered(player.position,position): host.hurt(position)
			var duration = maxf(1.0,home.distance_to(target)/520.0+.25) if boss else 1.0
			if cycle>duration:
				mode = "recover"
				cycle = 0
		elif mode == "recover":
			position = position.move_toward(home,95*delta)
			if cycle>1.4:
				mode = "rest"
				cycle = 0
	if kind=="moth" and host.flags.get("cage",false):harmless = true
	if not harmless and (player.position-Vector2(0,30)).distance_to(position)<(57 if boss else 31):
		host.hurt(position)
	queue_redraw()

func reset_pose() -> void:
	position = home
	mode = "rest"
	cycle = 0

func ellipse(center: Vector2,radius: Vector2,color: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(24):pts.append(center+Vector2(cos(i*TAU/24),sin(i*TAU/24))*radius)
	draw_colored_polygon(pts,color)

func _draw() -> void:
	var col: Color = COLORS.get(kind,Color(.45,.52,.66))
	var s = 1.8 if boss else 1.0
	if mode=="warn":
		draw_arc(Vector2.ZERO,36*s,0,TAU,32,Color(1,.55,.27),2,true)
		draw_line(Vector2(0,-50*s),Vector2(0,-65*s),Color(1,.8,.4),4,true)
		if kind in ["kite","wasp","stormkeeper","furnace"]:draw_arc(to_local(target),45,0,TAU,32,Color(1,.55,.3,.7),2,true)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*s)
	if kind=="stag":
		ellipse(Vector2(0,3),Vector2(39,24),Color(.42,.43,.27))
		draw_circle(Vector2(15,-29),19,Color(.56,.60,.36))
		for side in [-1,1]:
			draw_polyline(PackedVector2Array([Vector2(15+side*8,-43),Vector2(15+side*17,-68),Vector2(15+side*27,-80)]),Color(.9,.8,.46),4,true)
			draw_line(Vector2(15+side*17,-68),Vector2(15+side*32,-65),Color(.9,.8,.46),3,true)
		for x in [-24,-9,16,29]:draw_line(Vector2(x,12),Vector2(x,35),Color(.32,.36,.21),6,true)
	elif kind=="warden":
		ellipse(Vector2.ZERO,Vector2(43,31),Color(.18,.47,.53))
		for side in [-1,1]:
			draw_colored_polygon(PackedVector2Array([Vector2(side*25,-5),Vector2(side*65,-27),Vector2(side*51,24)]),Color(.34,.74,.75))
		draw_arc(Vector2.ZERO,27,0,TAU,36,Color(.5,.9,.96),3,true)
	elif kind=="furnace":
		for i in range(10):
			var v=Vector2.from_angle(i*TAU/10+clock*.2)*38
			draw_circle(v,11,Color(.35,.28,.26))
		draw_circle(Vector2.ZERO,37,Color(.22,.24,.26))
		draw_circle(Vector2.ZERO,24,Color(1,.35,.08))
		draw_circle(Vector2.ZERO,13+sin(clock*6)*3,Color(1,.79,.32))
	elif kind=="stormkeeper":
		draw_arc(Vector2(0,-5),44,0,TAU,48,Color(.5,.79,1,.8),3,true)
		draw_colored_polygon(PackedVector2Array([Vector2(0,-38),Vector2(-38,38),Vector2(0,21),Vector2(38,38)]),Color(.39,.48,.68))
		draw_circle(Vector2(0,-17),17,Color(.75,.85,.96))
		for side in [-1,1]:draw_line(Vector2(side*18,-20),Vector2(side*47,-47+sin(clock*3)*6),Color(.58,.85,1),4,true)
	elif kind in ["moth","wasp","kite"]:
		var flutter = 8+absf(sin(clock*18))*12
		ellipse(Vector2(-15,-4),Vector2(22,flutter),col)
		ellipse(Vector2(15,-4),Vector2(22,flutter),col)
		draw_circle(Vector2.ZERO,10,col.darkened(.55))
		if kind=="kite":draw_colored_polygon(PackedVector2Array([Vector2(-30,0),Vector2(0,-18),Vector2(30,0),Vector2(0,14)]),col)
	elif kind=="eel":
		var pts = PackedVector2Array()
		for i in range(12):pts.append(Vector2((i-6)*6,sin(clock*4+i*.5)*8))
		draw_polyline(pts,col,12,true)
		draw_polyline(pts,Color(.6,.93,1),2,true)
	elif kind=="crab":
		ellipse(Vector2.ZERO,Vector2(24,17),col)
		for side in [-1,1]:
			draw_line(Vector2(side*15,5),Vector2(side*31,14),col,4,true)
			if not harmless:draw_arc(Vector2(side*29,-14),8,0,PI*1.4,16,col,5,true)
	elif kind in ["sentinel","guard"] or boss:
		draw_rect(Rect2(-23,-29,46,53),col.darkened(.22))
		draw_circle(Vector2(0,-23),27,col)
		if boss:
			for side in [-1,1]:
				draw_polyline(PackedVector2Array([Vector2(side*15,-40),Vector2(side*27,-63),Vector2(side*36,-59)]),Color(.9,.79,.48),4,true)
		if kind=="guard":
			draw_line(Vector2(25,-6),Vector2(44,-38 if mode=="warn" else 15),Color(.7,.63,.47),6,true)
			draw_rect(Rect2(31,-52 if mode=="warn" else 0,28,25),Color(.35,.33,.3))
	elif kind=="wisp":
		draw_circle(Vector2.ZERO,22,Color(.65,.5,1,.16))
		draw_colored_polygon(PackedVector2Array([Vector2(0,-22),Vector2(17,0),Vector2(0,24),Vector2(-17,0)]),col)
		draw_polyline(PackedVector2Array([Vector2(0,-18),Vector2(-5,-3),Vector2(5,5),Vector2(0,20)]),Color(.16,.12,.3),2,true)
	else:
		ellipse(Vector2.ZERO,Vector2(26,17),col)
		for i in range(4):draw_line(Vector2((i-1.5)*12,6),Vector2((i-1.5)*12+sin(clock*9+i)*5,23),col.darkened(.3),3,true)
	for side in [-1,1]:draw_circle(Vector2(side*6,-7),3,Color(1,.83,.42))
	draw_set_transform(Vector2.ZERO)
	if kind=="sentinel" and mode in ["warn","attack"]:
		draw_line(Vector2(0,-7),Vector2(signf(target.x-position.x)*300,-7),Color(1,.59,.22,.65 if mode=="attack" else .2),5 if mode=="attack" else 2,true)
