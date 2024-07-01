extends Node

var user = load("res://user.tscn")

var mic_capture: VOIPInputCapture

var users = {} # {Peer ID: AudioStreamPlayer}

var packets_received = 0
var packets_sent = 0

func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	
	var mic_bus = AudioServer.get_bus_index("Mic")
	mic_capture = AudioServer.get_bus_effect(mic_bus, 0)
	mic_capture.packet_ready.connect(self._voice_packet_ready)
	

func _peer_connected(id):
	if id != 1:
		print("Peer connected with ID ", id)
		users[id] = user.instantiate()
		add_child(users[id])
	
func _peer_disconnected(id):
	if id != 1:
		print("Peer disconnected with ID ", id)
		users[id].queue_free()
		users.erase(id)


func _voice_packet_ready(packet):
	if not multiplayer.is_server():
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_voice_packet_received.rpc(packet)
			packets_sent += 1
			#print("Packets sent: ", packets_sent)
	
@rpc("any_peer", "unreliable")
func _voice_packet_received(packet):
	packets_received += 1
	print("Packets received: ", packets_received)
	var sender_id = multiplayer.get_remote_sender_id()
	users[sender_id].stream.push_packet(packet)


func _process(_delta):
	mic_capture.send_test_packets()
