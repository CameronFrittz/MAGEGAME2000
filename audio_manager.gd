extends Node

@onready var input : AudioStreamPlayer
var index : int
var effect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback
var inputThreshold = 0.00
var receiveBuffer := PackedFloat32Array()
@export var outputPath : NodePath
var compressor : AudioEffectCompressor
var gate : AudioEffectGate
var eq : AudioEffectEQ
var downsample_rate = 8000  # Downsampling to 8kHz
var sampling_rate = 44100  # Default to 44.1kHz, you might need to adjust this
var send_interval = 0.1  # Send data every 0.1 seconds
var send_timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setupAudio(get_multiplayer_authority())
	pass # Replace with function body.

func setupAudio(id):
	input = $Input
	var VOIP = get_node(outputPath)
	get_node(outputPath).set_multiplayer_authority(id, true)
	set_multiplayer_authority(id, true)
	if is_multiplayer_authority():
		input.stream = AudioStreamMicrophone.new()
		input.play()
		index = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(index, 0)
		# Add compressor for dynamic range compression
		gate = AudioEffectGate.new()
		gate.threshold_db = -18  # Adjust as needed
		AudioServer.add_bus_effect(index, gate, 1)
		compressor = AudioEffectCompressor.new()
		compressor.threshold = -25  # Adjust as needed
		compressor.ratio = 8.0
		compressor.attack_us = 5
		compressor.gain = 9.0  # Adjust as needed
		AudioServer.add_bus_effect(index, compressor, 2)
		eq = AudioEffectEQ.new()
		eq.set_band_gain_db(0, -10)
		eq.set_band_gain_db(1, -15)
		eq.set_band_gain_db(5, -5)
		AudioServer.add_bus_effect(index, eq, 3)
		
		# Get the sampling rate
		sampling_rate = AudioServer.get_mix_rate()
		
	playback = VOIP.get_stream_playback()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_multiplayer_authority():
		processMic(delta)
	processVoice()
	pass

func processMic(delta):
	send_timer += delta
	if send_timer < send_interval:
		return
	send_timer = 0.0

	var sterioData : PackedVector2Array = effect.get_buffer(effect.get_frames_available())
	
	if sterioData.size() > 0:
		var data = PackedFloat32Array()
		data.resize(sterioData.size())
		var maxAmplitude := 0.0
		
		for i in range(0, sterioData.size(), sampling_rate / downsample_rate):
			var value = (sterioData[i].x + sterioData[i].y) / 2
			maxAmplitude = max(value, maxAmplitude)
			data[i] = value
		if maxAmplitude < inputThreshold:
			return 

		# Quantizing the audio data
		var quantized_data = quantize_audio(data)
		sendData.rpc(quantized_data)
		
func quantize_audio(data: PackedFloat32Array) -> PackedByteArray:
	var byte_data = PackedByteArray()
	for sample in data:
		byte_data.append(float_to_byte(sample))  # Convert float to byte array
	return byte_data
	
func float_to_byte(value: float) -> int:
	# More aggressive quantization from -1.0 to 1.0 into 0 to 255
	return int(clamp((value + 1.0) * 127.5, 0, 255))

func processVoice():
	if receiveBuffer.size() <= 0:
		return
	
	for i in range(min(playback.get_frames_available(), receiveBuffer.size())):
		playback.push_frame(Vector2(receiveBuffer[0], receiveBuffer[0]))
		receiveBuffer.remove_at(0)
		
@rpc("any_peer", "call_remote", "unreliable_ordered")
func sendData(data : PackedByteArray):
	receiveBuffer.append_array(dequantize_audio(data))
	
func dequantize_audio(data: PackedByteArray) -> PackedFloat32Array:
	var float_data = PackedFloat32Array()
	for byte in data:
		float_data.append(byte_to_float(byte))  # Convert byte array back to float
	return float_data
	
func byte_to_float(value: int) -> float:
	# Simple dequantization from 0 to 255 into -1.0 to 1.0
	return float(value) / 127.5 - 1.0
