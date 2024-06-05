extends MultiplayerSpawner
@onready var monsters_node = get_node("/root/MAGEGAME/Monsters")  # Adjust this path to your actual node
var monster_scene = preload("res://monster.tscn")
var spawn_points = []  # Array to hold spawn point positions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_points()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
@rpc("any_peer")
func spawn_function() -> Node:
	var currentMonster = monster_scene.instantiate()
	var spawn_index = randi() % spawn_points.size()
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var spawn_position = spawn_points[spawn_index] + offset
	currentMonster.global_position = spawn_position
	%Monsters.add_child(currentMonster)
	return currentMonster

func set_spawn_points():
	# Assuming spawn points are placed in a group called "SpawnPoints"
	for point in get_tree().get_nodes_in_group("SpawnPoints"):
		spawn_points.append(point.global_position)
