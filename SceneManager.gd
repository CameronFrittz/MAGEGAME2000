extends Node2D

@onready var PlayerSpawner_node = get_node("PlayerSpawner")
@onready var MultiplayerController = get_node("/root/Control")


func _enter_tree():
	get_node("PlayerSpawner").set_multiplayer_authority(1)

func _ready():
	for peer in multiplayer.get_peers():
		spawn_my_player(MultiplayerController.nickname)
	pass

func _process(_delta):
	pass
	
	
@rpc("any_peer", "reliable")
func spawn_my_player(nickname: String) -> void:
	if multiplayer.is_server():
		var index = 0
		var spawn_points = get_tree().get_nodes_in_group("PlayerSpawnPoint")
		var peer = multiplayer.get_remote_sender_id()
		var data := {"peer_id": peer, "nickname": nickname}
		var currentPlayer = PlayerSpawner_node.spawn(data)
		if index < spawn_points.size():
				var spawn = spawn_points[index]
				currentPlayer.global_position = spawn.global_position
		index += 1
		return
