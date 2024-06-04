extends CharacterBody2D

const SPEED = 300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Add the gravity if needed, for example if your game has vertical movement.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Get input from WASD and determine the movement direction in isometric space.
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input_vector.length() > 0:
		input_vector = input_vector.normalized() * SPEED
		# Convert to isometric movement
		velocity.x = input_vector.x - input_vector.y
		velocity.y = (input_vector.x + input_vector.y) * 0.5
	else:
		# Decelerate both components of the velocity towards zero using float for the lerp factor
		velocity.x = lerp(velocity.x, 0, 10.0 * delta)
		velocity.y = lerp(velocity.y, 0, 10.0 * delta)

	# Move the character using the updated velocity property
	move_and_slide()
