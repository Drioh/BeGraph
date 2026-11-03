extends CharacterBody3D

@export var speed: float = 8.0
@export var acceleration: float = 30.0
@export var friction: float = 25.0
@export var mouse_sensitivity: float = 0.003

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _mouse_captured: bool = false

func _ready() -> void:
	add_to_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_mouse_captured = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.is_pressed():
			_mouse_captured = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if spring_arm:
				spring_arm.spring_length = clampf(spring_arm.spring_length - 0.5, 2.0, 15.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if spring_arm:
				spring_arm.spring_length = clampf(spring_arm.spring_length + 0.5, 2.0, 15.0)

	elif event is InputEventMouseMotion and _mouse_captured:
		if spring_arm:
			spring_arm.rotation.y -= event.relative.x * mouse_sensitivity
			spring_arm.rotation.x = clampf(spring_arm.rotation.x - event.relative.y * mouse_sensitivity, -PI * 0.45, PI * 0.1)

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	# Input movement relative to camera
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0

	input_dir = input_dir.normalized()

	var cam_yaw: float = spring_arm.rotation.y if spring_arm else 0.0
	var move_dir := (Transform3D().rotated(Vector3.UP, cam_yaw) * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if move_dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, move_dir.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	move_and_slide()
