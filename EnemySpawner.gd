extends Node2D

@export var enemy_scene = PackedScene
@export var spawn_interval = 1.0
@export var max_enemies = 10
var enemies_spawned = 0

func _ready():
	start_spawning()

func start_spawning():
	while enemies_spawned < max_enemies:
		var enemy = enemy_scene.instance()
		enemy.position = get_random_position()
		get_parent().add_child(enemy)  # Adding to the game world
		enemies_spawned += 1
		enemy.connect("enemy_died", self, "_on_enemy_died")  # Assuming enemies signal when they die
		await get_tree().create_timer(spawn_interval).timeout
	# This loop will keep running until the maximum number of enemies have been spawned

func get_random_position():
	var x = randf_range(0, get_viewport_rect().size.x)
	var y = randf_range(0, get_viewport_rect().size.y)
	return Vector2(x, y)

func _on_enemy_died():
	enemies_spawned -= 1
