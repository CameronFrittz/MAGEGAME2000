extends Node2D

@onready var PlayerSpawner_node = get_node("PlayerSpawner")
@onready var MultiplayerController = get_node("/root/Control")
var currentPlayer

func _enter_tree():
	get_node("PlayerSpawner").set_multiplayer_authority(1)

func _ready():
	if not is_multiplayer_authority():
		spawn_my_player.rpc_id(1, MultiplayerController.nickname)
		
	pass

func _process(_delta):
	pass
	
	
@rpc("any_peer", "reliable")
func spawn_my_player(nickname: String) -> void:
	if multiplayer.is_server():
		var peer = multiplayer.get_remote_sender_id()
		var data := {"peer_id": peer, "nickname": nickname}
		currentPlayer = PlayerSpawner_node.spawn(data)
		return
