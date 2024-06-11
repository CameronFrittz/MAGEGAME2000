extends Node2D

@onready var timer: Timer = Timer.new()
@onready var _mesh_instance = $Sprite2D
@onready var _multi_mesh_instance = $MultiMeshInstance2D

const MAX_ALPHA: float = 0.70

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	_do_distribution()
	add_child(timer)
	self.modulate.a = 0.0  # Start with the sprite fully transparent
	timer.wait_time = 0.02  # Faster steps for fade-in
	timer.one_shot = false
	timer.timeout.connect(_fadein_step)
	timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Performs a single step of the fade-in.
func _fadein_step() -> void:
	self.modulate.a += 0.065  # Adjust alpha by a larger amount each step
	if self.modulate.a >= MAX_ALPHA:
		self.modulate.a = MAX_ALPHA
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
	self.modulate.a -= 0.02  # Adjust alpha by a small amount each step
	if self.modulate.a <= 0.0:
		self.modulate.a = 0.0
		timer.stop()
		queue_free()

func _do_distribution():
	var multi_mesh = _multi_mesh_instance.multimesh
	multi_mesh.mesh = _mesh_instance.mesh
	var screen_size = get_viewport_rect().size
	for i in multi_mesh.instance_count:
		var s = Vector2(.5,.5)
		var v = Vector2(randf() * screen_size.x/2, randf() * screen_size.y/2)
		var t = Transform2D(0.0, s, 0 , v)
		multi_mesh.set_instance_transform_2d(i, t)
