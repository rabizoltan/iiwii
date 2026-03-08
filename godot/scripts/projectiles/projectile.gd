extends Area3D

@export var speed: float = 18.0
@export var lifetime: float = 1.8
@export var damage: float = 1.0

var _direction: Vector3 = Vector3.FORWARD
var _remaining_life: float = 0.0


func _ready() -> void:
	_remaining_life = lifetime
	body_entered.connect(_on_body_entered)


func initialize(direction: Vector3) -> void:
	var horizontal_direction := direction
	horizontal_direction.y = 0.0

	if horizontal_direction.length_squared() <= 0.0:
		_direction = Vector3.FORWARD
	else:
		_direction = horizontal_direction.normalized()


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	_remaining_life -= delta

	if _remaining_life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return

	if body.has_method("apply_damage"):
		body.apply_damage(damage)

	queue_free()
