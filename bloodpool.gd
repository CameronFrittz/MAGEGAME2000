extends Node2D

@onready var timer: Timer = Timer.new()
@onready var sprite: Sprite2D = $Sprite2D
const MAX_ALPHA: float = 0.70

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(timer)
	sprite.modulate.a = 0.0  # Start with the sprite fully transparent
	timer.wait_time = 0.02  # Faster steps for fade-in
	timer.one_shot = false
	timer.timeout.connect(_fadein_step)
	timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Performs a single step of the fade-in.
func _fadein_step() -> void:
	sprite.modulate.a += 0.065  # Adjust alpha by a larger amount each step
	if sprite.modulate.a >= MAX_ALPHA:
		sprite.modulate.a = MAX_ALPHA
		timer.stop()
		_start_wait()

# Waits for 3 seconds before starting the fade-out.
func _start_wait() -> void:
	timer.timeout.disconnect(_fadein_step)
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_start_fadeout)
	timer.start()

# Starts the fade-out effect.
func _start_fadeout() -> void:
	timer.timeout.disconnect(_start_fadeout)
	timer.wait_time = 0.1
	timer.one_shot = false
	timer.timeout.connect(_fadeout_step)
	timer.start()

# Performs a single step of the fade-out.
func _fadeout_step() -> void:
	sprite.modulate.a -= 0.02  # Adjust alpha by a small amount each step
	if sprite.modulate.a <= 0.0:
		sprite.modulate.a = 0.0
		timer.stop()
		queue_free()
