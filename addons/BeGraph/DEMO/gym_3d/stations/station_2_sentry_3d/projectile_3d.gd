extends Area3D

@export var speed: float = 18.0
@export var velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if velocity != Vector3.ZERO:
		global_position += velocity * delta
	else:
		global_position -= global_transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D and body.name.begins_with("Sentry")):
		queue_free()
