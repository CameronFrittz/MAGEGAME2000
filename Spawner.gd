extends Node

# Export variables to easily adjust from the editor
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0  # seconds between spawns
@export var max_enemies: int = 5
@export var spawn_points: Array[Vector2] = []  # Possible spawn locations

var num_enemies: int = 0  # Track the number of currently active enemies

func _ready():
	# Start the spawning process
	start_spawning()

func start_spawning():
	while true:
		if num_enemies < max_enemies:
			spawn_enemy()
			var timer = get_tree().create_timer(spawn_interval)
			await timer.timeout
		else:
			# If maximum enemies are reached, wait a bit before checking again
			var timer = get_tree().create_timer(spawn_interval)
			await timer.timeout

func spawn_enemy():
	var enemy_instance = enemy_scene.instantiate()
	add_child(enemy_instance)  # Add the enemy to the scene tree (consider a specific parent node if needed)

	# Randomly select a spawn point
	if spawn_points.size() > 0:
		enemy_instance.global_position = spawn_points[randi() % spawn_points.size()]

	num_enemies += 1
	# Connect the enemy's signal for when it's defeated or destroyed
	enemy_instance.defeated.connect(_on_enemy_defeated.bind(self))

func _on_enemy_defeated():
	num_enemies -= 1  # Decrement the count of active enemies
	
	
