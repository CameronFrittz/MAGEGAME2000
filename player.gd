extends CharacterBody2D

# Constants for movement, attack, and mana properties
const SPEED: float = 100.0
const DASH_SPEED: float = 300.0
const DASH_DURATION: float = 0.20
const DASH_COOLDOWN: float = 0.55
const ATTACK_DURATION: float = 0.4  # Duration of attack animation
const FIREBALL_SPEED: float = 400.0
const FIREBALL_MANA_COST = 8  
const MANA_REGEN_RATE: float = 3.0  # Mana regeneration rate per second
const DAMAGE_COOLDOWN = 1  # 3 seconds cooldown
var damage_cooldown_timer: float = 0.0
@export var enemyattackdamage = randf_range(40, 80)
@onready var playercamera = $Camera2D as Camera2D
# Preloaded scenes and instances
var fireball_scene = preload("res://fireball.tscn")    
var reticle_scene = preload("res://reticle.tscn")
var freeze_reticle_scene = preload("res://FreezeReticle.tscn")  # Updated preload
var reticle_instance = null
var stun_reticle_texture = preload("res://SPRITES/StunReticle.png")  # Texture for the freeze effect visualization

# Constants and variables for the freeze ability
const FREEZE_RADIUS: float = 150.0  # Adjust this for your game's scale
const FREEZE_DURATION: float = 3.5
const FREEZE_COOLDOWN: float = 5.0
var freeze_cooldown_timer: float = 0.0
var freeze_reticle: Area2D = null  # Variable to hold the freeze reticle instance
const FREEZE_MANA_COST: int = 10  # Mana cost for using the freeze ability

# State management
var is_knocked_back: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0
var flash_duration: float = 0.2
var is_flashing: bool = false
var is_dashing: bool = false
var is_attacking: bool = false
var is_firing: bool = false
var using_mouse: bool = true
var reset_reticle_pressed: bool = false
var is_aiming_freeze: bool = false

# Health and Mana Properties
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var mana: float = 100.0
@export var max_mana: float = 100.0

# Timing for actions
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var last_damage_time: float = -3.0  # Track the last time damage was applied

# Animation and movement
var move_direction: float = 0.0
var moving: bool = false
var anim_direction: String = "S"
var anim_mode: String = "Idle"

# HUD and sprite references
@onready var hud = get_node("/root/MAGEGAME/hud/")
@onready var sprite = $Sprite2D
@onready var game_manager = get_node("/root/GameManager")  # Reference to the GameManager

# Zoom properties for camera control
const ZOOM_LEVELS: Array = [Vector2(0.4, 0.4), Vector2(0.6, 0.6), Vector2(0.8, 0.8), Vector2(1.0, 1.0), Vector2(1.2, 1.2), Vector2(1.4, 1.4), Vector2(1.6, 1.6), Vector2(1.8, 1.8), Vector2(2.0, 2.0), Vector2(2.2, 2.2)]
const ZOOM_SPEED: float = 3
var current_zoom_index: int = 4  # Default to the middle zoom level
var target_zoom: Vector2 = ZOOM_LEVELS[current_zoom_index]

# Joystick sensitivity
const JOYSTICK_SENSITIVITY: float = 325.0  # Adjust as needed

# Process input for various actions
func _input(event): 
	if event.is_action_pressed("fire"):
		if not reticle_instance:
			reticle_instance = reticle_scene.instantiate()
		if not reticle_instance.is_inside_tree():
			add_child(reticle_instance)
			reticle_instance.z_index = 0  # Set the z_index here
		is_firing = true
		# Determine if the mouse is on screen
		if is_mouse_on_screen():
			using_mouse = true
		else:
			using_mouse = false
	elif event.is_action_released("fire"):
		if reticle_instance and reticle_instance.is_inside_tree():
			fire_fireball(reticle_instance.global_position)
			remove_child(reticle_instance)
		is_firing = false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom_level(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom_level(-1)

	if Input.is_action_just_pressed("reset_reticle"):
		if not reset_reticle_pressed:
			reset_reticle_position()
			reset_reticle_pressed = true
	elif Input.is_action_just_released("reset_reticle"):
		reset_reticle_pressed = false
	# Handle zoom in and zoom out actions
	if Input.is_action_just_pressed("zoom_in"):
		change_zoom_level(-1)  # Zoom in by moving to a smaller zoom level
	elif Input.is_action_just_pressed("zoom_out"):
		change_zoom_level(1)  # Zoom out by moving to a larger zoom level

	if Input.is_action_pressed("freeze"):
		show_freeze_reticle()  # Show the freeze reticle while holding the button
	elif Input.is_action_just_released("freeze"):
		trigger_freeze()  # Trigger the freeze effect on button release

# Reset reticle position to player's position
func reset_reticle_position():
	if reticle_instance and reticle_instance.is_inside_tree():
		reticle_instance.global_position = global_position
func has_authority() -> bool:
	return $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()

# Helper function to determine if the mouse is on screen
func is_mouse_on_screen() -> bool:
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	return mouse_pos.x >= 0 and mouse_pos.y >= 0 and mouse_pos.x <= viewport_size.x and mouse_pos.y <= viewport_size.y

@onready var fireball_spawner = get_node("FireballSpawner")


func fire_fireball(target_position):
	if has_authority() and mana >= FIREBALL_MANA_COST:
		var fireball_instance = fireball_spawner.spawn()
		#Getting a breakpoint here because it returns a null ptr
		fireball_instance.position = position
		fireball_instance.rotation = (target_position - position).angle()
		mana -= FIREBALL_MANA_COST
		update_mana_display()
		%FireBallSFX.pitch_scale = randf_range(1.3,1.6)
		%FireBallSFX.playing = true
	else:
		print("Not enough mana to cast fireball or no authority.")

# Update mana display on the HUD
func update_mana_display():
	if has_authority():
		hud.update_mana(mana, max_mana)

# Change the zoom level based on input
func change_zoom_level(change: int):
	current_zoom_index = clamp(current_zoom_index + change, 0, ZOOM_LEVELS.size() - 1)
	target_zoom = ZOOM_LEVELS[current_zoom_index]



func _process(delta: float):
	if playercamera:
		playercamera.zoom = playercamera.zoom.lerp(target_zoom, ZOOM_SPEED * delta)
	if mana < max_mana:
		mana += MANA_REGEN_RATE * delta
		mana = min(mana, max_mana)  # Ensure mana does not exceed max
		update_mana_display()  # Update HUD with new mana level
	if damage_cooldown_timer > 0:
		damage_cooldown_timer -= delta

	# Update freeze cooldown timer
	if freeze_cooldown_timer > 0:
		freeze_cooldown_timer -= delta

	# Update reticle position based on input
	if is_firing:
		if using_mouse:
			update_reticle_position_with_mouse()
		else:
			update_reticle_position_with_joystick(delta)

	# Update freeze reticle position if aiming
	if is_aiming_freeze and freeze_reticle:
		freeze_reticle.global_position = global_position

# Update reticle position based on mouse position
func update_reticle_position_with_mouse():
	if reticle_instance and reticle_instance.is_inside_tree():
		reticle_instance.global_position = get_global_mouse_position()

# Update reticle position based on joystick direction
func update_reticle_position_with_joystick(delta: float):
	if has_authority():
		var joystick_direction_x = Input.get_action_strength("ui_right_stick_x") - Input.get_action_strength("ui_left_stick_x")
		var joystick_direction_y = Input.get_action_strength("ui_down_stick_y") - Input.get_action_strength("ui_up_stick_y")
		var joystick_direction = Vector2(joystick_direction_x, joystick_direction_y) * JOYSTICK_SENSITIVITY

		print("Joystick Direction X: ", joystick_direction_x)
		print("Joystick Direction Y: ", joystick_direction_y)

		# Ensure the joystick direction takes both positive and negative values
		if reticle_instance and reticle_instance.is_inside_tree():
			reticle_instance.position += joystick_direction * delta

			# Ensure the reticle stays within the viewport
			var viewport_rect = get_viewport_rect()
			reticle_instance.position.x = clamp(reticle_instance.position.x, -999, viewport_rect.size.x)
			reticle_instance.position.y = clamp(reticle_instance.position.y, -999, viewport_rect.size.y)

			print("Reticle Position: ", reticle_instance.position)  # Debug print

# Initial setup of the scene
func _ready(): 
	if has_authority():
		var player_camera = get_node("Camera2D")
		player_camera.make_current()
	if hud:
		update_hud()
	else:
		print("HUD not found. Check the node path or structure.")
	if playercamera:
		target_zoom = playercamera.zoom
	else:
		print("Cannot invert transform due to zero scale")
	assert(scale.x != 0 and scale.y != 0, "Scale should not be zero to avoid inversion errors.")
	target_zoom = Vector2(1, 1)
	flash_timer = Timer.new()
	flash_timer.wait_time = flash_duration
	flash_timer.one_shot = true
	flash_timer.timeout.connect(stop_flash)
	add_child(flash_timer)

# Manage physical movements and attacks
func _physics_process(delta: float) -> void:
	if has_authority(): 
		if is_knocked_back:
			knockback_timer -= delta
			if knockback_timer <= 0:
				is_knocked_back = false
				knockback_velocity = Vector2.ZERO
			velocity = knockback_velocity
		else:
			handle_dash(delta)
			handle_attack(delta)
			handle_movement(delta)

		move_and_slide()  # Apply the calculated velocity
		AnimationLoop()
		if not is_attacking:
			$AttackArea.set_monitoring(false)

# Handle movement based on player input
func handle_movement(_delta: float) -> void:
	if not is_dashing and not is_attacking:
		var input_vector: Vector2 = Vector2.ZERO
		input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

		if input_vector.length() > 0:
			input_vector = input_vector.normalized()
			moving = true
			move_direction = rad_to_deg(input_vector.angle())
		else:
			moving = false

		self.velocity = input_vector * SPEED
	move_and_slide()

# Handle dashing mechanics
func handle_dash(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			update_post_dash_velocity()

	dash_cooldown_timer -= delta

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_dashing and not is_attacking:
		start_dash()

# Start a dash movement
func start_dash() -> void:
	var dash_direction: Vector2 = Vector2.ZERO
	dash_direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dash_direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if dash_direction.length() == 0:
		dash_direction = Vector2(cos(deg_to_rad(move_direction)), sin(deg_to_rad(move_direction)))

	dash_direction = dash_direction.normalized()
	self.velocity = dash_direction * DASH_SPEED
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN + DASH_DURATION
	moving = true

	# Adjust collision mask and layer on the Player node
	var player_node = get_node_or_null(".")  # Adjust the node path as necessary
	if player_node:
		# Set bit 0 and 1 to be disabled and bit 31 to be enabled
		var mask = player_node.collision_mask
		var layer = player_node.collision_layer

		mask &= ~(1 << 0)  # Disable bit 0
		mask &= ~(1 << 1)  # Disable bit 1
		mask |= (1 << 31)  # Enable bit 31

		layer &= ~(1 << 0)  # Disable bit 0
		layer &= ~(1 << 1)  # Disable bit 1
		layer |= (1 << 31)  # Enable bit 31

		player_node.collision_mask = mask
		player_node.collision_layer = layer

	else:
		print("Player node not found")


	sprite.modulate.a = 0.4  # Make player semi-transparent
	%DashSFX.pitch_scale = randf_range(2,2.5)
	%DashSFX.playing = true
	

# Handle attack mechanics
func handle_attack(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0 and is_attacking:
		is_attacking = false

	if Input.is_action_just_pressed("attack") and not is_attacking and not is_dashing:
		start_attack()

# Start an attack sequence
func start_attack() -> void:
	is_attacking = true
	attack_timer = ATTACK_DURATION
	self.velocity = Vector2.ZERO
	$AttackArea.set_monitoring(true)
	%AttackSFX.pitch_scale = randf_range(.9,1.3)
	%AttackSFX.playing = true

# Update velocity after dashing
func update_post_dash_velocity() -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		self.velocity = input_vector * SPEED
	else:
		self.velocity = Vector2.ZERO

	var player_node = get_node_or_null(".")  # Adjust the node path as necessary
	if player_node:
		# Re-enable bit 0 and 1, keep bit 31 enabled
		var mask = player_node.collision_mask
		var layer = player_node.collision_layer

		mask |= (1 << 0)  # Enable bit 0
		mask |= (1 << 1)  # Enable bit 1
		mask |= (1 << 31)  # Ensure bit 31 is still enabled (optional if it's intended)

		layer |= (1 << 0)  # Enable bit 0
		layer |= (1 << 1)  # Enable bit 1
		layer |= (1 << 31)  # Ensure bit 31 is still enabled (optional if it's intended)

		player_node.collision_mask = mask
		player_node.collision_layer = layer
	else:
		print("Player node not found")

	sprite.modulate.a = 1.0  # Restore full opacity
	push_enemies_away_from_landing(global_position)

func push_enemies_away_from_landing(landing_position: Vector2) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var enemy_collision = enemy.get_node("CollisionPolygon2D")  # Ensure correct node name
		if enemy_collision and enemy_collision.global_position.distance_to(landing_position) < 50:  # Example distance
			var push_direction = enemy.last_movement_direction  # Use the enemy's last movement direction
			if push_direction.length() == 0:
				push_direction = (enemy.global_position - landing_position).normalized()  # Fallback if no movement direction
			var push_distance = 10  # Adjust based on your game's needs
			enemy.global_position += push_direction * push_distance
			print("Pushed enemy:", enemy.name)  # Debug print

# Manage animations based on state
func AnimationLoop():
	if is_attacking:
		var attack_anim = "Melee_" + anim_direction
		get_node("AnimationPlayer").play(attack_anim)
	else:
		if moving:
			if move_direction >= -15 and move_direction < 15:
				anim_direction = "E"
			elif move_direction >= 15 and move_direction < 60:
				anim_direction = "SE"
			elif move_direction >= 60 and move_direction < 120:
				anim_direction = "S"
			elif move_direction >= 120 and move_direction < 165:
				anim_direction = "SW"
			elif move_direction >= -60 and move_direction < -15:
				anim_direction = "NE"
			elif move_direction >= -120 and move_direction < -60:
				anim_direction = "N"
			elif move_direction >= -165 and move_direction < -120:
				anim_direction = "NW"
			elif move_direction >= 165 or move_direction < -165:
				anim_direction = "W"
			anim_mode = "Walk"
		else:
			anim_mode = "Idle"

		var animation_name = anim_mode + "_" + anim_direction
		get_node("AnimationPlayer").play(animation_name)


# Update HUD with current health and mana
func update_hud() -> void:
	if has_authority():
		if hud:
			hud.update_health(health, max_health)
			hud.update_mana(mana, max_mana)
		else:
			print("HUD not found. Check the node path or structure.")

# Detect enemy hits within attack area
func _on_attack_area_area_entered(area):
	if area.is_in_group("enemies"):
		print("Enemy hit detected.")
	var enemy = area
	while enemy and not enemy.has_method("apply_damage"):
		enemy = enemy.get_parent()
	if is_instance_valid(enemy):
		enemy.apply_damage(enemyattackdamage)
	else:
		print("apply_damage method not found in the parent hierarchy")


# Sends a request to the server to apply damage
func apply_damage(damage_amount: int):
	if multiplayer.is_server():
		_apply_damage(damage_amount)
	else:
		rpc_id(1, "_request_damage", damage_amount)

# Applies damage to the player

func _apply_damage(damage_amount: int):
	health -= damage_amount
	if health <= 0:
		die()
	update_hud()
	start_flash()

@rpc("any_peer", "call_local")
func _request_damage(damage_amount: int):
	if multiplayer.is_server():
		rpc_id(multiplayer.get_unique_id(), "_apply_damage", damage_amount)


# Asynchronous function to handle controller vibration
func start_controller_vibration(duration: float, weak_magnitude: float, strong_magnitude: float):
	# Iterate through all connected joypads
	for joypad_id in Input.get_connected_joypads():
		Input.start_joy_vibration(joypad_id, weak_magnitude, strong_magnitude, duration)

	# Wait for the specified duration before stopping the vibration
	await get_tree().create_timer(duration).timeout
	for joypad_id in Input.get_connected_joypads():
		Input.stop_joy_vibration(joypad_id)

# Apply knockback to the player
func apply_knockback(source_position: Vector2, power: float):
	var direction = (global_position - source_position).normalized()
	knockback_velocity = direction * power
	is_knocked_back = true
	knockback_timer = 0.2
	is_dashing = false
	is_attacking = false

# Timer for visual effects
var flash_timer: Timer

# Start flashing effect on taking damage
func start_flash():
	sprite.modulate = Color(1, 0, 0)
	flash_timer.start()

# Stop flashing effect
func stop_flash():
	sprite.modulate = Color(1, 1, 1)

@onready var fret_spawner = get_node("FreezeReticleSpawner")

# Function to show the freeze reticle without triggering freeze
func show_freeze_reticle():
	if has_authority() and freeze_reticle == null and freeze_cooldown_timer <= 0:
		freeze_reticle = fret_spawner.spawn()
		#Getting a breakpoint here because it returns a null ptr
		freeze_reticle.get_node("Sprite2D").texture = stun_reticle_texture
		freeze_reticle.get_node("Sprite2D").modulate.a = 0.5  # Set alpha to 0.5 while aiming
		freeze_reticle.global_position = global_position
		freeze_reticle.z_index = 5
		var scale_factor = (4.25 * FREEZE_RADIUS) / freeze_reticle.get_node("Sprite2D").texture.get_size().x
		freeze_reticle.scale = Vector2(scale_factor, scale_factor)
		freeze_reticle.freeze_duration = FREEZE_DURATION  # Set the freeze duration for the reticle
		is_aiming_freeze = true  # Indicate that the player is aiming the freeze spell

# Function to trigger freeze and remove the reticle after the freeze duration
func trigger_freeze():
	if has_authority() and freeze_reticle and mana >= FREEZE_MANA_COST and freeze_cooldown_timer <= 0:
		freeze_cooldown_timer = FREEZE_COOLDOWN
		mana -= FREEZE_MANA_COST  # Deduct mana cost
		update_mana_display()  # Update HUD after mana change
		is_aiming_freeze = false  # Indicate that the player is no longer aiming the freeze spell
		freeze_reticle.get_node("Sprite2D").modulate.a = 1.0  # Set alpha to 1 when spell is activated
		freeze_reticle.activate_spell()  # Activate the spell to start freezing enemies
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy.global_position.distance_to(freeze_reticle.global_position) <= FREEZE_RADIUS:
				enemy.freeze(FREEZE_DURATION)
		# Set a timer to remove the reticle after the freeze duration
		var timer = Timer.new()
		timer.wait_time = FREEZE_DURATION
		timer.one_shot = true
		timer.timeout.connect(_on_freeze_duration_timeout)
		add_child(timer)
		timer.start()
	else:
		print("Cannot cast freeze: insufficient mana, skill is on cooldown, or no authority.")

# Function to remove the reticle after the freeze duration
func _on_freeze_duration_timeout():
	if freeze_reticle:
		freeze_reticle.queue_free()
		freeze_reticle = null

# Handle player death
func die():
	print("Player has died")
	emit_signal("player_died")  # Signal that other parts of the game can listen to

	# Optionally play a death animation before removing the player
	var animation_player = get_node("AnimationPlayer")
	if animation_player:
		animation_player.play("Death")
		await get_tree().create_timer(animation_player.get_current_animation_length()).timeout
	queue_free()
