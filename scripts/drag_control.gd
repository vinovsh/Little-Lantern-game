class_name LanternDragControl
extends Node2D
## One finger owns movement until release, even outside the pad.
signal axis_changed(value: float)
const TRAVEL := 46.0
const DEAD_ZONE := 0.15
var finger := -1
var axis := 0.0
var knob := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.index == finger and (not event.pressed or event.canceled):
			release()
			get_viewport().set_input_as_handled()
		elif event.pressed and not event.canceled and finger == -1:
			var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			if point.length() <= 82:
				finger = event.index
				move_knob(point)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		move_knob(get_global_transform_with_canvas().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()

func move_knob(point: Vector2) -> void:
	knob = point.limit_length(TRAVEL)
	var strength := clampf(point.x / TRAVEL, -1, 1)
	axis = signf(strength) * maxf(0, (absf(strength) - DEAD_ZONE) / (1 - DEAD_ZONE))
	axis_changed.emit(axis)
	queue_redraw()

func release() -> void:
	var was_active := finger != -1 or axis != 0
	finger = -1
	axis = 0
	knob = Vector2.ZERO
	if was_active:
		axis_changed.emit(0.0)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release()
	elif what == NOTIFICATION_EXIT_TREE:
		release()

func _draw() -> void:
	var gold := Color(1, .79, .36)
	draw_circle(Vector2.ZERO, 68, Color(.025, .07, .10, .8))
	draw_arc(Vector2.ZERO, 67, 0, TAU, 72, Color(.87, .84, .7, .7), 2, true)
	draw_arc(Vector2.ZERO, 46, 0, TAU, 64, Color(.87, .84, .7, .18), 1, true)
	for direction in [-1, 1]:
		var x: float = direction * 51.0
		draw_polyline(PackedVector2Array([Vector2(x-direction*5,-7),Vector2(x,0),Vector2(x-direction*5,7)]),Color(.9,.86,.72,.7),2,true)
	draw_circle(knob + Vector2(0, 3), 28, Color(0, 0, 0, .3))
	draw_circle(knob, 27, Color(.20, .27, .27) if finger == -1 else Color(.37,.31,.16))
	draw_arc(knob, 27, 0, TAU, 48, gold if finger != -1 else Color(.9,.85,.67), 2, true)
	draw_circle(knob, 9, Color(1,.79,.36,.3))
