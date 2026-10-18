class_name LanternTouchControl
extends TouchScreenButton
var glyph := ""
var active_gold := false
var button_radius := 39.0
var font := preload("res://assets/fonts/Interface.ttf")

func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = button_radius + 9
	shape = circle
	shape_centered = true
	passby_press = false
	visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	pressed.connect(queue_redraw)
	released.connect(queue_redraw)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var held := is_pressed()
	var gold := Color(1,.79,.36)
	draw_circle(Vector2.ZERO,button_radius,Color(.04,.09,.12,.83))
	if active_gold or held:
		draw_circle(Vector2.ZERO,button_radius-2,Color(1,.68,.17,.15 if not held else .4))
	draw_arc(Vector2.ZERO,button_radius-1,0,TAU,64,gold if active_gold or held else Color(.87,.84,.7,.8),1.5,true)
	var size := 29
	var width := font.get_string_size(glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(font,Vector2(-width/2,10),glyph,HORIZONTAL_ALIGNMENT_LEFT,-1,size,gold if active_gold else Color(.98,.94,.82))

