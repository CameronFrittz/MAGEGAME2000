extends RigidBody2D
@export var health : int = 20
var flash_duration: float = 0.2
var is_flashing: bool = false
var flash_timer: Timer
var last_movement_direction: Vector2 = Vector2.ZERO
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("enemies")
	flash_timer = Timer.new()  # Create a new Timer instance
	flash_timer.wait_time = flash_duration  # Set the wait time
	flash_timer.one_shot = true  # Ensure it fires only once
	flash_timer.timeout.connect(stop_flash)  # Connect timeout signal to stop_flash
	add_child(flash_timer)  # Add the Timer as a child of the current node
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func apply_damage(damage_amount: int):
		health -= damage_amount
		print("Applied damage: ", damage_amount, " New health: ", health)
		if health <= 0:
			breakbox()
		else:
			start_flash()
		#%BoxSFX.pitch_scale = randf_range(1,1.5)
		#%BoxSFX.playing = true
		
func breakbox() -> void:
	queue_free()
	pass # Replace with function body.
	
func start_flash():
	self.modulate = Color(1, 0, 0)
	flash_timer.start()

func stop_flash():
	self.modulate = Color(1, 1, 1)
	
func update_last_movement_direction(velocity: Vector2) -> void:
	if velocity.length() > 0:
		last_movement_direction = velocity.normalized()
	else:
		last_movement_direction = Vector2.ZERO


func _on_hurt_area_area_entered(area: Area2D) -> void:
	apply_damage(20)
