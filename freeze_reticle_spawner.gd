extends MultiplayerSpawner
var fret_scene = preload("res://FreezeReticle.tscn")  
var stun_reticle_texture = preload("res://SPRITES/StunReticle.png")  # Texture for the freeze effect visualization

func _ready() -> void:
	set_spawn_path("/root/MAGEGAME/Spawnables") 
	spawn_function = Callable(self, "spawn_fret")


func _process(_delta: float) -> void:
	pass
	
func spawn_fret(data: Variant) -> Node:
	var currentFret = fret_scene.instantiate()
	currentFret.set_multiplayer_authority(data.peer_id, true)
	currentFret.get_node("Sprite2D").texture = stun_reticle_texture
	currentFret.get_node("Sprite2D").modulate.a = 0.5  # Set alpha to 0.5 while aiming
	return currentFret
