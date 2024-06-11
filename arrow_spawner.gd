extends MultiplayerSpawner
var arrow_scene = preload("res://arrow.tscn")  

func _ready() -> void:
	set_spawn_path("/root/MAGEGAME/Spawnables") 
	spawn_function = Callable(self, "spawn_arrow")


func _process(_delta: float) -> void:
	pass
	
func spawn_arrow(data: Variant) -> Node:
	var currentArrow = arrow_scene.instantiate()
	currentArrow.global_position = data.spawn_position
	var direction = (data.target_position - data.spawn_position).normalized()
	currentArrow.rotation = direction.angle()
	currentArrow.set_multiplayer_authority(data.peer_id)
	return currentArrow
