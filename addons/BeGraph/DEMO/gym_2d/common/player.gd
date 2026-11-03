extends CharacterBody2D

@export var speed: float = 320.0
@export var acceleration: float = 1800.0
@export var friction: float = 1600.0
@export var radius: float = 18.0
@export var body_color: Color = Color(0.2, 0.7, 1.0, 1.0) # Bright cyan-blue circle
@export var border_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@onready var camera: Camera2D = $Camera2D

var _target_zoom: Vector2 = Vector2.ONE
var _min_zoom: float = 0.5
var _max_zoom: float = 2.0

func _ready() -> void:
	add_to_group("player")
	if camera:
		_target_zoom = camera.zoom

func _draw() -> void:
	# Draw filled circle
	draw_circle(Vector2.ZERO, radius, body_color)
	# Draw border ring
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, border_color, 2.5, true)
	# Draw inner core
	draw_circle(Vector2.ZERO, radius * 0.35, Color(1, 1, 1, 0.9))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = (_target_zoom * 1.1).clamp(Vector2.ONE * _min_zoom, Vector2.ONE * _max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = (_target_zoom * 0.9).clamp(Vector2.ONE * _min_zoom, Vector2.ONE * _max_zoom)

func _physics_process(delta: float) -> void:
	# Direction from both built-in actions and direct WASD/arrow keys
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0

	dir = dir.normalized()

	if dir != Vector2.ZERO:
		velocity = velocity.move_toward(dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	# Smooth camera zoom
	if camera:
		camera.zoom = camera.zoom.lerp(_target_zoom, 10.0 * delta)
