extends Node2D

@onready var tree_sfx = $TreeSFX
@onready var timer = Timer.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(timer)
	timer.timeout.connect(_on_Timer_timeout)
	
	# Start the timer with an initial random offset
	var initial_offset = randf_range(0, 5)
	timer.start(initial_offset)

# Called when the timer times out
func _on_Timer_timeout() -> void:
	tree_sfx.play()

	# Set the timer to a random interval between 10 and 15 seconds
	var interval = randf_range(10, 15)
	timer.start(interval)
