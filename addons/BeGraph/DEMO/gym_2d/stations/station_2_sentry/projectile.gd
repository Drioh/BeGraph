extends Area2D

@export var speed: float = 380.0
@export var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Auto-free after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		position += velocity * delta
	else:
		position += transform.x * speed * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.25, 0.2, 1.0))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.4, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Flash player briefly or push back
		queue_free()
	elif not (body is CharacterBody2D and body.name.begins_with("Sentry")):
		queue_free()
