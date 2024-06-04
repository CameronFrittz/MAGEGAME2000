extends Node2D

# Constants for round timing
const ROUND_DURATION = 120  # Duration of each round in seconds
const INTER_ROUND_DURATION = 5  # Duration between rounds in seconds
var alive_enemies = 0
# Enemy spawn information
var rounds = [5, 10, 20, 30, 50, 70, 90, 120, 150, 180, 250, 300, 350, 400, 420, 440, 500]
var current_round = 0
var enemy_scene = preload("res://monster.tscn")  # Assuming you have an enemy scene ready

# Manage round and inter-round timers
var round_timer = Timer.new()
var inter_round_timer = Timer.new()
var hud
var spawn_timer = Timer.new()  # Timer for controlling spawn intervals
var enemies_to_spawn = 0  # This will track how many enemies are left to spawn
@onready var monsters_node = get_node("/root/MAGEGAME/Monsters")  # Adjust this path to your actual node

# Manage spawn points
var spawn_points = []  # Array to hold spawn point positions

func _ready():
	hud = get_node("/root/MAGEGAME/hud")  # Ensure correct path
	initialize_timers()
	set_spawn_points()
	start_round()  # Start the first round immediately

func initialize_timers():
	add_child(round_timer)
	add_child(inter_round_timer)
	round_timer.wait_time = ROUND_DURATION
	inter_round_timer.wait_time = INTER_ROUND_DURATION

	round_timer.timeout.connect(on_round_timeout)
	inter_round_timer.timeout.connect(on_inter_round_timeout)
	
	# Set up the spawn timer
	spawn_timer.wait_time = .1  # Spawn every second
	spawn_timer.one_shot = false  # Ensure it repeats
	spawn_timer.timeout.connect(spawn_single_enemy)
	add_child(spawn_timer)

func set_spawn_points():
	# Assuming spawn points are placed in a group called "SpawnPoints"
	for point in get_tree().get_nodes_in_group("SpawnPoints"):
		spawn_points.append(point.global_position)

func start_round():
	if current_round < rounds.size():
		current_round += 1
		print("Starting Round: ", current_round)
		rpc("rpc_update_round_counter", current_round, rounds.size())
		enemies_to_spawn = rounds[current_round - 1]  # Ensure this is set correctly
		spawn_timer.start()  # Make sure this is only started once per round
		round_timer.start()
	else:
		print("No more rounds to start.")

func on_round_timeout():
	round_timer.stop()
	print("Round ", current_round, " timed out.")
	if alive_enemies > 0:
		print("Enemies still alive, waiting for round to end naturally.")
	else:
		print("No enemies left, ending round.")
		end_round()

func start_inter_round_timer():
	inter_round_timer.stop()  # Stop any existing inter-round timer before starting a new one
	print("Inter-round break started.")
	inter_round_timer.start()

func on_inter_round_timeout():
	inter_round_timer.stop()  # Ensure the inter-round timer is stopped
	start_round()  # Start the next round

func spawn_enemies(count):
	enemies_to_spawn = count  # How many enemies are left to spawn
	spawn_timer.start()
	alive_enemies = count  # Initialize the number of alive enemies correctly
	rpc("rpc_update_enemies_left_counter", alive_enemies)  # Update HUD right after setting the count
	print("Spawning enemies for round ", current_round)
	for i in range(count):
		var enemy = enemy_scene.instantiate()
		var spawn_index = randi() % spawn_points.size()
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		enemy.global_position = spawn_points[spawn_index] + offset
		monsters_node.call_deferred("add_child", enemy)  # Use call_deferred to add the enemy to the scene
		enemy.enemy_died.connect(_on_monster_enemy_died)
		# Update HUD for enemies left
	
func spawn_single_enemy():
	if enemies_to_spawn > 0:
		var enemy = enemy_scene.instantiate()
		var spawn_index = randi() % spawn_points.size()
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var spawn_position = spawn_points[spawn_index] + offset
		
		if multiplayer.is_server():
			enemy.players_parent = %Players
			enemy.global_position = spawn_position
			monsters_node.call_deferred("add_child", enemy)
			enemy.enemy_died.connect(_on_monster_enemy_died)
			rpc("client_spawn_enemy", spawn_position)
		
		enemies_to_spawn -= 1
		alive_enemies += 1
		rpc("rpc_update_enemies_left_counter", alive_enemies)
	else:
		spawn_timer.stop()

# Ensure the client-side spawning method is correctly declared
@rpc("call_remote")
func client_spawn_enemy(position):
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	monsters_node.call_deferred("add_child", enemy)
	enemy.enemy_died.connect(_on_monster_enemy_died)

func end_round():
	print("Round ", current_round, " completed.")
	if current_round < rounds.size():
		start_inter_round_timer()  # Prepare the inter-round break
	else:
		print("All rounds completed! Game Over!")

func _on_monster_enemy_died():
	print("An enemy has died.")
	alive_enemies -= 1
	rpc("rpc_update_enemies_left_counter", alive_enemies)
	if alive_enemies <= 0:
		print("All enemies defeated, preparing to end round.")
		end_round()

# RPC to update round counter on all clients
@rpc("any_peer")
func rpc_update_round_counter(current_round, total_rounds):
	print("Updating round counter: ", current_round, "/", total_rounds)
	hud.update_round_counter(current_round, total_rounds)

# RPC to update enemies left counter on all clients
@rpc("any_peer")
func rpc_update_enemies_left_counter(enemies_left):
	print("Updating enemies left counter: ", enemies_left)
	hud.update_enemies_left_counter(enemies_left)
