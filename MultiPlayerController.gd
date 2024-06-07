# MultiplayerConnector.gd
extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer

func _ready():
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server on %s" % [port])
		_on_host_button_down()
		await get_tree().create_timer(1).timeout
		_on_start_game_button_down()
	else:
		_on_join_button_down()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func _process(_delta):
	pass

func peer_connected(id):
	if id == 1:
		print("Connected to Server")
	if id != 1:
		print("Player connected: " + str(id))

func peer_disconnected(id):
	print("Player Disconnected: " + str(id))

func connected_to_server():
	print("Connecting to server")
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())

func connection_failed():
	print("Connection failed")

func _on_host_button_down():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 8)
	if error != OK:
		print("Cannot host: " + str(error))
		return
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())

func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	multiplayer.set_multiplayer_peer(peer)

func _on_start_game_button_down():
	StartGame.rpc()

@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://MAGEGAME.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name": name,
			"id": id,
			"score": 0
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)
