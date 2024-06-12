extends MultiplayerSpawner
var fireball_scene = preload("res://fireball.tscn")  

func _ready() -> void:
	set_spawn_path("/root/MAGEGAME/Spawnables") 
	spawn_function = Callable(self, "spawn_fireball")


func _process(_delta: float) -> void:
	pass
	
func spawn_fireball(data: Variant) -> Node:
	var currentFireball = fireball_scene.instantiate()
	currentFireball.global_position = data.spawn_position
	var direction = (data.target_position - data.spawn_position).normalized()
	currentFireball.rotation = direction.angle()
	currentFireball.set_multiplayer_authority(data.peer_id, true)
	return currentFireball
