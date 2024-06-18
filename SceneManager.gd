extends Node2D

@onready var PlayerSpawner_node = get_node("PlayerSpawner")
@onready var MultiplayerController = get_node("/root/Control")
@onready var batspawner_node = get_node("/root/MAGEGAME/BatSpawner")
var currentPlayer

func _enter_tree():
	get_node("PlayerSpawner").set_multiplayer_authority(1)

func _ready():
	if not is_multiplayer_authority():
		spawn_my_player.rpc_id(1, MultiplayerController.nickname,MultiplayerController.player_scene_selection)
	if is_multiplayer_authority():
				var currentBat = batspawner_node.spawn()
				var currentBat1 = batspawner_node.spawn()
				var currentBat2 = batspawner_node.spawn()
	pass

func _process(_delta):
	pass
	
	
@rpc("any_peer", "reliable")
func spawn_my_player(nickname: String,scene_path: String) -> void:
	if multiplayer.is_server():
		var peer = multiplayer.get_remote_sender_id()
		var data := {"peer_id": peer, "nickname": nickname, "scene_path": scene_path}
		currentPlayer = PlayerSpawner_node.spawn(data)
		return
