extends Node2D

@onready var animation_player_fade = $AnimationPlayerFade
var is_faded_out = false  # Boolean to track fade-out state

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var modulate_color = modulate
	modulate_color.a = 1.0
	modulate = modulate_color
	pass

func _process(_delta: float) -> void:
	pass
	
func _on_area_2d_area_entered(_area: Area2D):
	# Trigger the fade-out effect only if not already faded out
	if not is_faded_out and not animation_player_fade.is_playing():
		animation_player_fade.play("FadeOut")
		is_faded_out = true

func _on_area_2d_area_exited(_area: Area2D):
	# Trigger the fade-in effect only if faded out and animation is not playing
	if is_faded_out and not animation_player_fade.is_playing():
		animation_player_fade.play("FadeIn")
		is_faded_out = false
