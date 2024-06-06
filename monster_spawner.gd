extends MultiplayerSpawner
@onready var monsters_node = get_node("/root/MAGEGAME/Monsters") 
var monster_scene = preload("res://monster.tscn")
var spawn_points = []  

func _ready() -> void:
	set_spawn_points()


func _process(delta: float) -> void:
	pass
	
func spawn_monster() -> Node:
	var currentMonster = monster_scene.instantiate()
	var spawn_index = randi() % spawn_points.size()
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	var spawn_position = spawn_points[spawn_index] + offset
	currentMonster.global_position = spawn_position
	%Monsters.add_child(currentMonster, true)
	return currentMonster

func set_spawn_points():
	for point in get_tree().get_nodes_in_group("SpawnPoints"):
		spawn_points.append(point.global_position)
