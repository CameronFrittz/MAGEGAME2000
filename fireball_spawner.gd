extends MultiplayerSpawner
var fireball_scene = preload("res://fireball.tscn")  

func _ready() -> void:
	spawn_function = Callable(self, "spawn_fireball")


func _process(_delta: float) -> void:
	pass
	
func spawn_fireball(data: Variant) -> Node:
	var currentFireball = fireball_scene.instantiate()
	var direction = (data.target_position - data.spawn_position).normalized()
	currentFireball.rotation = direction.angle()
	currentFireball.set_multiplayer_authority(data.peer_id, true)
	return currentFireball
