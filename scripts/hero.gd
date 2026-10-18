class_name LanternHero
extends CharacterBody2D
signal jumped
signal landed
const SPEED := 270.0
const GRAVITY := 1550.0
const JUMP := -610.0
var sprite: AnimatedSprite2D
var facing := 1
var lantern_on := true
var coyote := 0.0
var buffer := 0.0
var was_grounded := false
var protection := 0.0
var frozen := false
var touch_direction := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 17
	shape.height = 65
	collider.shape = shape
	collider.position.y = -32
	add_child(collider)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = make_frames()
	sprite.position = Vector2(-9, -64)
	sprite.scale = Vector2(0.4,0.4)
	add_child(sprite)
	sprite.play("idle")

static func make_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var atlas := preload("res://assets/art/hero.png")
	var animations := {"idle": [0,1,2,3], "run": [4,5,6,7], "jump": [9,10], "fall": [11], "celebrate": [12,13,14,15]}
	for name in animations:
		frames.add_animation(name)
		frames.set_animation_loop(name,name != "jump")
		frames.set_animation_speed(name, 9 if name == "run" else (5 if name == "celebrate" else 3))
		for index in animations[name]:
			var texture := AtlasTexture.new()
			texture.atlas = atlas
			texture.region = Rect2((index % 4) * 352, (index / 4) * 320, 352,320)
			frames.add_frame(name, texture)
	return frames

func _physics_process(delta: float) -> void:
	if frozen:
		return
	protection = maxf(0, protection - delta)
	var direction := clampf(Input.get_axis("left", "right") + touch_direction, -1, 1)
	velocity.x = move_toward(velocity.x, direction * SPEED, (2100 if is_on_floor() else 1300) * delta)
	if direction != 0:
		facing = 1 if direction > 0 else -1
	if is_on_floor():
		coyote = 0.1
	else:
		coyote = maxf(0, coyote - delta)
	buffer = maxf(0, buffer - delta)
	if Input.is_action_just_pressed("jump"):
		buffer = 0.12
	if buffer > 0 and coyote > 0:
		velocity.y = JUMP
		buffer = 0
		coyote = 0
		jumped.emit()
	if Input.is_action_just_released("jump") and velocity.y < -220:
		velocity.y *= 0.55
	velocity.y = minf(1000, velocity.y + GRAVITY * delta)
	move_and_slide()
	position.x = maxf(24, position.x)
	if is_on_floor() and not was_grounded:
		landed.emit()
	was_grounded = is_on_floor()
	sprite.flip_h = facing < 0
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0 else "fall")
	else:
		sprite.play("run" if absf(velocity.x) > 18 else "idle")
	sprite.modulate.a = (0.75 if Save.data.settings.reduced_effects else 0.5 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.012))) if protection > 0 else 1.0

func reset_at(point: Vector2) -> void:
	position = point
	velocity = Vector2.ZERO
	coyote = 0
	buffer = 0
	protection = 1.5
	frozen = false
	was_grounded = false

