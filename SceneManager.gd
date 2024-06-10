extends Node2D

@onready var PlayerSpawner_node = get_node("PlayerSpawner")

func _ready():
	var index = 0
	var spawn_points = get_tree().get_nodes_in_group("PlayerSpawnPoint")
	for player_id in GameManager.Players:
		if player_id == 1:
			continue
		var currentPlayer = PlayerSpawner_node.spawn()
		#Getting a breakpoint here because it returns a null ptr
		currentPlayer.name = str(player_id)
		
		if index < spawn_points.size():
			var spawn = spawn_points[index]
			currentPlayer.global_position = spawn.global_position
			print("Assigning player ", player_id, " to spawn point ", index, " at position ", spawn.global_position)
		
		# Assign the camera only if this player is the local player
		if player_id == multiplayer.get_unique_id():
			var player_camera = currentPlayer.get_node("Camera2D")
			player_camera.make_current()
		
		index += 1
	pass

func _process(_delta):
	pass
