extends Node2D

var score = 0
@onready var player = $Player
@onready var hud = $HUD  # Assuming you have a HUD node for displaying score and messages

func _ready():
	player.timeout.connect(_on_player_died)
	player.timeout.connect(_on_enemy_killed)  # Connect this signal from wherever it's emitted

func _on_enemy_killed():
	score += 1
	hud.update_score(score)

func _on_player_died():
	get_tree().call_group("enemies", "set_active", false)  # Disable all enemy scripts
	hud.show_game_over()
	get_tree().pause = true  # Pause the game
