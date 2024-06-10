extends MultiplayerSpawner
var fret_scene = preload("res://FreezeReticle.tscn")  

func _ready() -> void:
	spawn_function = Callable(self, "spawn_fret")


func _process(_delta: float) -> void:
	pass
	
func spawn_fret(data: Variant) -> Node:
	var currentFret = fret_scene.instantiate()
	return currentFret
