extends MultiplayerSpawner
@onready var monsters_node = get_node("/root/MAGEGAME/Monsters") 
var bat_scene = preload("res://bat.tscn")
var spawn_points = []  

func _ready() -> void:
	spawn_function = Callable(self, "spawn_monster")
	set_spawn_points()
	
	


func _process(_delta: float) -> void:
	pass
	
func spawn_monster(_data: Variant) -> Node:
	var currentMonster = bat_scene.instantiate()
	var spawn_index = randi() % spawn_points.size()
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var spawn_position = spawn_points[spawn_index] + offset
	currentMonster.global_position = spawn_position
	return currentMonster



func set_spawn_points():
	for point in get_tree().get_nodes_in_group("BatSpawnPoint"):
		spawn_points.append(point.global_position)
