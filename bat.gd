extends CharacterBody2D

# Constants for behavior
var SPEED: float = 180
const RETREAT_DISTANCE: float = 200
const MIN_DISTANCE: float = 50
const RETREAT_COOLDOWN: float = 5.0
# Health and flashing properties
@export var health: int = 50
var flash_duration: float = 0.2
var is_flashing: bool = false
@export var is_dying: bool = false
@export var is_frozen: bool = false
var monsters_parent: Node
var players_parent: Node
var target_player: Node2D
var bloodpool = preload("res://bloodpool.tscn")
# AI state control
enum State { PATROL, APPROACH, RETREAT, COLLIDED }
var current_state = State.PATROL

var circle_radius: float = 20.0
var circle_speed: float = 8.0
var angle: float = 0.0
var circle_center: Vector2

@export var wander_radius: float = 100.0
@export var wander_speed: float = 50.0
@export var approach_distance: float = 400.0
var wander_target: Vector2
var is_wandering: bool = false




var retreat_target: Vector2
# Node references
@onready var sprite = $Sprite2D
@onready var game_manager = get_node("/root/GameManager")
var flash_timer: Timer
@export var is_hit_recently = false
@export var hit_timer: float = 0.0
var health_checked = false
var hit_cooldown: float = 0.5  # Cooldown in seconds between hits
@onready var pick_target_timer = Timer.new()
@onready  var health_bar = $ProgressBar 
var last_movement_direction: Vector2 = Vector2.ZERO
func _ready():
	health_bar.visible = false
	players_parent = get_node("/root/MAGEGAME/Players")
	monsters_parent = get_node("/root/MAGEGAME/Monsters")  # Change this to the correct path
	add_to_group("enemies")
	flash_timer = Timer.new()  # Create a new Timer instance
	flash_timer.wait_time = flash_duration  # Set the wait time
	flash_timer.one_shot = true  # Ensure it fires only once
	flash_timer.timeout.connect(stop_flash)  # Connect timeout signal to stop_flash
	add_child(flash_timer)  # Add the Timer as a child of the current node

	# Setup pick target timer
	pick_target_timer.wait_time = 2.0  # Set the interval to 2 seconds
	pick_target_timer.one_shot = false
	pick_target_timer.autostart = true
	pick_target_timer.timeout.connect(pick_target)
	add_child(pick_target_timer)

	circle_center = global_position  # Initialize the circle center to the bat's starting position




func update_last_movement_direction(_velocity: Vector2) -> void:
	if _velocity.length() > 0:
		last_movement_direction = _velocity.normalized()
		if abs(last_movement_direction.x) > abs(last_movement_direction.y):
			if last_movement_direction.x > 0:
				get_node("AnimationPlayer").play("fly_right")
			elif last_movement_direction.x < 0:
				get_node("AnimationPlayer").play("fly_left")
		else:
			get_node("AnimationPlayer").play("fly_up_down")
	else:
		last_movement_direction = Vector2.ZERO
		get_node("AnimationPlayer").play("fly_up_down")


func _physics_process(delta: float):
	if health_checked == false and health != 50:
		$ProgressBar.visible = true
		health_checked = true
	if is_hit_recently:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit_recently = false

	if target_player and is_instance_valid(target_player):
		var distance_to_player = global_position.distance_to(target_player.position)
		if distance_to_player < approach_distance:
			current_state = State.APPROACH
		else:
			current_state = State.PATROL

		match current_state:
			State.PATROL:
				velocity = wander(delta)
			State.APPROACH:
				velocity = fly_in_circle(delta, target_player.position)
			State.RETREAT:
				velocity = retreat_from_player(delta)
			State.COLLIDED:
				velocity = retreat_from_player(delta)
	else:
		# If target_player is not valid, attempt to pick a new target
		pick_target()
		velocity = wander(delta)  # Default to wandering if no target is found

	update_last_movement_direction(velocity)  # Update the last movement direction
	move_and_slide()  # Move the monster with the assigned velocity




func fly_in_circle(delta: float, target_position: Vector2) -> Vector2:
	# Increment the angle for circular motion
	angle += circle_speed * delta

	# Calculate the offset position in the circular path
	var offset_x = circle_radius * cos(angle)
	var offset_y = circle_radius * sin(angle)
	var offset = Vector2(offset_x, offset_y)

	# Calculate the direction to the target position
	var direction_to_target = (target_position - global_position).normalized()

	# Apply a fraction of the offset to create circular motion while approaching
	var approach_velocity = direction_to_target * SPEED * 0.5
	var circular_velocity = offset.normalized() * SPEED * 0.5

	# Combine both velocities
	var combined_velocity = approach_velocity + circular_velocity

	return combined_velocity.normalized() * SPEED


func wander(_delta: float) -> Vector2:
	if not is_wandering or global_position.distance_to(wander_target) < 10.0:
		wander_target = global_position + Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		is_wandering = true

	var direction_to_target = (wander_target - global_position).normalized()
	return direction_to_target * wander_speed



# Function to pick the nearest target player
func pick_target() -> void:
	if not players_parent:
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


func approach_player(_delta: float) -> Vector2:
	# Ensure that the target is valid
	if target_player and is_instance_valid(target_player):
		var distance = global_position.distance_to(target_player.position)
		if distance > MIN_DISTANCE:
			return (target_player.position - global_position).normalized() * SPEED
	else:
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
		return 
	if multiplayer.is_server():
		if is_hit_recently:
			return  # Skip applying damage if we are within the cooldown period
		health -= damage_amount
		is_hit_recently = true
		hit_timer = hit_cooldown  # Reset hit cooldown timer
		if health_bar:
			health_bar.value = health  # Ensure the health bar is updated
		print("Applied damage: ", damage_amount, " New health: ", health)
		if health <= 0:
			die()
		else:
			start_flash()
		%GruntSFX.pitch_scale = randf_range(1,1.5)
		%GruntSFX.playing = true
	else:
		var droppedbp = bloodpool.instantiate()
		droppedbp.position = global_position
		monsters_parent.add_child(droppedbp)
		%GruntSFX.pitch_scale = randf_range(1,1.5)
		%GruntSFX.playing = true
		
		
func apply_arrowdamage(damage_amount: int):
	if multiplayer.is_server():
		health -= damage_amount
		is_hit_recently = true
		hit_timer = hit_cooldown  # Reset hit cooldown timer
		if health_bar:
			health_bar.value = health  # Ensure the health bar is updated
		print("Applied damage: ", damage_amount, " New health: ", health)
		if health <= 0:
			die()
		else:
			start_flash()
		%GruntSFX.pitch_scale = randf_range(1,1.5)
		%GruntSFX.playing = true
	else:
		var droppedbp = bloodpool.instantiate()
		droppedbp.position = global_position
		monsters_parent.add_child(droppedbp)
		%GruntSFX.pitch_scale = randf_range(1,1.5)
		%GruntSFX.playing = true






func die():
	%GruntSFX.pitch_scale = randf_range(1,1.5)
	%GruntSFX.playing = true
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
	_enemy_died()
	

func _enemy_died():
	if is_multiplayer_authority():
		print("Despawning enemy")
		queue_free()  # This method will be called when the timer runs out

func _on_death_timeout():
	if is_multiplayer_authority():
		queue_free()  # This method will be called when the timer runs out
#
func freeze(duration):
	if is_multiplayer_authority():
		is_frozen = true
		if is_frozen == true:
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
	if is_multiplayer_authority():
		# Directly apply damage as this is for the freeze effect and should bypass normal hit cooldown
		health -= damage_amount
		health_bar.value = health  # Update the health bar's progress

		if health <= 0:
			die()
		else:
			# Flash to indicate freeze damage if needed or manage visuals separately
			start_flash()

func _apply_freeze_damage():
	if is_multiplayer_authority():
		apply_freeze_damage(int(randf_range(2, 5)))  # Apply 2-5 damage every second
