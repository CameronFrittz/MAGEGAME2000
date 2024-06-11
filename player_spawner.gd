extends MultiplayerSpawner
var player_scene = preload("res://player.tscn")
var spawn_points = []  

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_points()
	spawn_function = Callable(self, "spawn_player")
	

func spawn_player(data: Variant) -> Node:
	var currentPlayer = player_scene.instantiate()
	var spawn_index = randi() % spawn_points.size()
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var spawn_position = spawn_points[spawn_index] + offset
	currentPlayer.global_position = spawn_position
	currentPlayer.set_multiplayer_authority(data.peer_id, true)
	return currentPlayer



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_spawn_points():
	for point in get_tree().get_nodes_in_group("PlayerSpawnPoint"):
		spawn_points.append(point.global_position)
