extends CharacterBody2D

# Constants for behavior
var SPEED: float = 100
const RETREAT_DISTANCE: float = 200
const MIN_DISTANCE: float = 20
const RETREAT_COOLDOWN: float = 5.0

# Health and flashing properties
@export var health: int = 100
var flash_duration: float = 0.2
var is_flashing: bool = false
signal enemy_died
var is_dying: bool = false

var players_parent: Node
var target_player: Node2D

# AI state control
enum State { APPROACH, RETREAT, COLLIDED }
var current_state = State.APPROACH
var retreat_target: Vector2

# Node references
@onready var sprite = $Sprite2D
@onready var game_manager = get_node("/root/GameManager")
var flash_timer: Timer
var is_hit_recently = false
var hit_timer: float = 0.0
var hit_cooldown: float = 0.5  # Cooldown in seconds between hits
@onready var pick_target_timer = Timer.new()
@onready var health_bar = $ProgressBar

func _ready():
	players_parent = get_node("/root/MAGEGAME/Players")  # Change this to the correct path
	if not players_parent:
		print("Error: players_parent is null")
	else:
		print("players_parent successfully assigned")
	add_to_group("enemies")
	flash_timer = Timer.new()  # Create a new Timer instance
	flash_timer.wait_time = flash_duration  # Set the wait time
	flash_timer.one_shot = true  # Ensure it fires only once
	flash_timer.timeout.connect(stop_flash)  # Connect timeout signal to stop_flash
	add_child(flash_timer)  # Add the Timer as a child of the current node
	
	# Setup pick target timer
	pick_target_timer.wait_time = 2.0  # Set the interval to 5 seconds
	pick_target_timer.one_shot = false
	pick_target_timer.autostart = true
	pick_target_timer.timeout.connect(pick_target)
	add_child(pick_target_timer)

func _physics_process(delta: float):
	if is_hit_recently:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit_recently = false

	match current_state:
		State.APPROACH:
			velocity = approach_player(delta)
		State.RETREAT:
			velocity = retreat_from_player(delta)
		State.COLLIDED:
			velocity = retreat_from_player(delta)

	move_and_slide()  # Move the monster with the assigned velocity


# Function to pick the nearest target player
func pick_target() -> void:
	if not players_parent:
		print("Error: players_parent is null")
		return

	# Initially set the target_player to null
	target_player = null
	var min_distance = INF  # Start with a very large number
	
	# Iterate over all children of players_parent
	for child in players_parent.get_children():
		if child and child.has_method("get_position"):
			var distance = position.distance_to(child.position)
			# If the distance to the current child is smaller than the minimum distance found
			if distance < min_distance:
				min_distance = distance
				target_player = child

	if target_player:
		print("Target player assigned: ", target_player.name)
	else:
		print("No valid target player found")

func approach_player(_delta: float) -> Vector2:
	# Ensure that the target is valid
	if target_player and is_instance_valid(target_player):
		var distance = global_position.distance_to(target_player.position)
		if distance > MIN_DISTANCE:
			return (target_player.position - global_position).normalized() * SPEED
	else:
		print("Invalid target or too close. Picking new target.")
		# Pick a new target if the current one is invalid or too close
		pick_target()
		if target_player and is_instance_valid(target_player):
			return (target_player.position - global_position).normalized() * SPEED
	return Vector2.ZERO

func retreat_from_player(_delta):
	var direction = (retreat_target - global_position).normalized()
	var distance_to_target = global_position.distance_to(retreat_target)

	if distance_to_target > MIN_DISTANCE:
		return direction * SPEED
	else:
		current_state = State.APPROACH
		return Vector2.ZERO

func start_flash():
	sprite.modulate = Color(1, 0, 0)
	flash_timer.start()

func stop_flash():
	sprite.modulate = Color(1, 1, 1)


# Applies damage to the monster
func apply_damage(damage_amount: int):
	if is_hit_recently:
		return  # Skip applying damage if we are within the cooldown period

	if multiplayer.is_server():
		_apply_damage(damage_amount)
	else:
		rpc_id(1, "_request_damage", damage_amount)

@rpc("any_peer", "call_local")
func _request_damage(damage_amount: int):
	if multiplayer.is_server():
		_apply_damage(damage_amount)


func _apply_damage(damage_amount: int):
	if is_hit_recently:
		return  # Skip applying damage if we are within the cooldown period

	health -= damage_amount
	is_hit_recently = true
	hit_timer = hit_cooldown  # Reset hit cooldown timer

	rpc("_update_health", health)  # Update health on clients
	print("Applied damage: ", damage_amount, " New health: ", health)
	if health <= 0:
		die()
	else:
		start_flash()


@rpc("any_peer")
func _update_health(new_health: int):
	print("Updating health to ", new_health)
	health = new_health
	if health_bar:
		health_bar.value = health  # Ensure the health bar is updated
		
		
		
func die():
	if is_dying:
		return  # Prevent re-entry if already dying
	is_dying = true
	start_flash()
	SPEED = 0
	var deathpausetimer = Timer.new()  # Create a new Timer instance
	add_child(deathpausetimer)  # Add the Timer as a child of the current node
	deathpausetimer.wait_time = 0.5  # Set the wait time to 0.5 seconds to reduce delay
	deathpausetimer.one_shot = true  # Ensure it fires only once
	deathpausetimer.timeout.connect(_on_death_timeout)  # Connect timeout signal to a function
	deathpausetimer.start()  # Start the timer
	emit_signal("enemy_died")
	rpc("_enemy_died")

@rpc("any_peer")
func _enemy_died():
	print("Despawning enemy")
	queue_free()  # This method will be called when the timer runs out

func _on_death_timeout():
	print("Death timeout reached, removing enemy")
	queue_free()  # This method will be called when the timer runs out

func freeze(duration):
	set_physics_process(false)  # Stop the monster's movement and actions
	modulate = Color(0.5, 0.5, 1.0)  # Change color to indicate freezing

	# Set up and start the damage timer
	var damage_timer = Timer.new()
	add_child(damage_timer)
	damage_timer.wait_time = 1.0  # 1 second interval for damage application
	damage_timer.one_shot = false
	damage_timer.timeout.connect(_apply_freeze_damage)
	damage_timer.start()

	# Use an asynchronous coroutine to manage the freeze duration
	await get_tree().create_timer(duration).timeout
	damage_timer.queue_free()
	set_physics_process(true)
	modulate = Color(1, 1, 1)  # Restore original color

func apply_freeze_damage(damage_amount: int):
	# Directly apply damage as this is for the freeze effect and should bypass normal hit cooldown
	health -= damage_amount
	health_bar.value = health  # Update the health bar's progress

	if health <= 0:
		die()
	else:
		# Flash to indicate freeze damage if needed or manage visuals separately
		start_flash()

func _apply_freeze_damage():
	apply_freeze_damage(randf_range(2, 5))  # Apply 2-5 damage every second
