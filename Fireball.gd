extends Area2D

@export var speed: float = 200
@export var damage: int = randf_range(35,70)


func _ready():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 5  # Fireball will last 5 seconds
	timer.one_shot = true
	timer.timeout.connect(queue_free)  # Make sure to connect to the correct method
	timer.start()

func _physics_process(delta):
	position += Vector2(speed, 0).rotated(rotation) * delta
	
func _process(delta):
	var velocity = Vector2(speed, 0).rotated(rotation)
	position += velocity * delta

func on_timer_timeout():
	queue_free()  # This method will be called when the timer runs out

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		print("Enemy hit detected.")
	var enemy = area
	while enemy and not enemy.has_method("apply_damage"):
		enemy = enemy.get_parent()
	
	if enemy:
		enemy.apply_damage(damage)
	else:
		print("apply_damage method not found in the parent hierarchy")
