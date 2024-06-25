extends Node

@onready var input : AudioStreamPlayer = $Input
@export var outputPath : NodePath
var index : int
var effect : AudioEffectCapture
var playback : AudioStreamPlaybackVOIP
var inputThreshold = 0.00
var mic_capture: AudioEffectCapture
var VOIPPlayback : AudioStreamVOIP
var packets_received = 0
var packets_sent = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setupAudio(get_multiplayer_authority())

func setupAudio(id):
	var VOIP = get_node(outputPath)
	if VOIP:
		VOIP.set_multiplayer_authority(id)
	set_multiplayer_authority(id)
	if is_multiplayer_authority():
		var mic = AudioStreamMicrophone.new()
		input.stream = mic
		input.play()
		VOIPPlayback = AudioStreamVOIP.new()
		VOIP.stream = VOIPPlayback
		VOIP.play()
		var mic_bus = AudioServer.get_bus_index("Mic")
		mic_capture = AudioServer.get_bus_effect(mic_bus, 0)
		if mic_capture:
			mic_capture.packet_ready.connect(_on_voice_packet_ready)

func _on_voice_packet_ready(packet):
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_voice_packet_received.rpc(packet)
		packets_sent += 1
		print("Packets sent: ", packets_sent)

@rpc("any_peer", "unreliable")
func _voice_packet_received(packet):
	packets_received += 1
	print("Packets received: ", packets_received)
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == multiplayer.get_unique_id():
		if VOIPPlayback:
			VOIPPlayback.push_packet(packet)

func _process(_delta):
	if mic_capture:
		mic_capture.send_test_packets()
