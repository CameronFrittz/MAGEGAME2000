extends Area2D

@export var speed: float = 0.0
@export var damage: int =  int(randf_range(70,100))
var velocity

func _ready():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 25  
	timer.one_shot = true
	timer.timeout.connect(Callable(self, "_on_timer_timeout"))
	timer.start()

func _physics_process(delta):
	position += Vector2(speed, 0).rotated(rotation) * delta
	
func _process(delta):
	velocity = Vector2(speed, 0).rotated(rotation)
	position += velocity * delta

func _on_timer_timeout():
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		queue_free()  # This method will be called when the timer runs out

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		print("Enemy hit detected.")
	var enemy = area
	while enemy and not enemy.has_method("apply_arrowdamage"):
		enemy = enemy.get_parent()
	
	if enemy:
		enemy.apply_arrowdamage(damage)
		#if get_multiplayer_authority() == multiplayer.get_unique_id():
			#queue_free()
	else:
		print("apply_arrowdamage method not found in the parent hierarchy")
