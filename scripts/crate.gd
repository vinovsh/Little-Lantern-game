class_name LanternCrate
extends CharacterBody2D
var home = Vector2.ZERO
var floating = false
func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var collider = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(52,54)
	collider.shape = box
	collider.position.y = -27
	add_child(collider)
func step(delta: float, direction: float, surface: float) -> void:
	velocity.x = direction*135
	floating = surface<position.y+20
	if floating:
		velocity.y = clampf((surface-position.y)*5,-190,190)
	else:velocity.y = minf(700,velocity.y+1000*delta)
	move_and_slide()
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-26,-54,52,54),Color(.32,.24,.14))
	draw_rect(Rect2(-26,-54,52,54),Color(.85,.7,.42),false,3)
	draw_line(Vector2(-22,-50),Vector2(22,-4),Color(.65,.5,.29),4,true)
	draw_line(Vector2(22,-50),Vector2(-22,-4),Color(.65,.5,.29),4,true)
	draw_circle(Vector2(0,-27),8,Color(.9,.77,.46))
