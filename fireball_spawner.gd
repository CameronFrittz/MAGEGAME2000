extends MultiplayerSpawner
var fireball_scene = preload("res://fireball.tscn")  

func _ready() -> void:
	spawn_function = Callable(self, "spawn_fireball")


func _process(_delta: float) -> void:
	pass
	
func spawn_fireball(data: Variant) -> Node:
	var currentFireball = fireball_scene.instantiate()
	return currentFireball
