extends MultiplayerSpawner
var arrow_scene = preload("res://arrow.tscn")  
const MAX_CHARGE_TIME: float = 3.0  # Maximum time for charging the arrow
const MIN_ARROW_SPEED: float = 150.0  # Minimum speed for the arrow
const MAX_ARROW_SPEED: float = 900.0  # Maximum speed for the arrow
func _ready() -> void:
	set_spawn_path("/root/MAGEGAME/Spawnables") 
	spawn_function = Callable(self, "spawn_arrow")


func _process(_delta: float) -> void:
	pass
	
#func spawn_arrow(data: Variant) -> Node:
	#var currentArrow = arrow_scene.instantiate()
	#currentArrow.global_position = data.spawn_position
	#var direction = (data.target_position - data.spawn_position).normalized()
	#currentArrow.rotation = direction.angle()
	#currentArrow.set_multiplayer_authority(data.peer_id)
	#return currentArrow
	
	
	
func spawn_arrow(data: Variant) -> Node:
	var currentArrow = arrow_scene.instantiate()
	currentArrow.global_position = data.spawn_position
	var direction = (data.target_position - data.spawn_position).normalized()
	currentArrow.rotation = direction.angle()
	currentArrow.set_multiplayer_authority(data.peer_id, true)
	
	# Calculate arrow speed based on charge time
	var charge_ratio = clamp(data.charge_time / MAX_CHARGE_TIME, 0.0, 1.0)
	var arrow_speed = lerp(MIN_ARROW_SPEED, MAX_ARROW_SPEED, charge_ratio)
	currentArrow.speed = arrow_speed  # Assuming your arrow scene has a speed property
	
	return currentArrow
