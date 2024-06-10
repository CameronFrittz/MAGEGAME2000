extends MultiplayerSpawner
var player_scene = preload("res://player.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_function = Callable(self, "spawn_player")
	

func spawn_player(data: Variant) -> Node:
	var currentPlayer = player_scene.instantiate()
	currentPlayer.set_multiplayer_authority(data, true)
	return currentPlayer




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
