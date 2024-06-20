extends Node2D

@onready var animation_player_fade = $AnimationPlayerFade
var is_faded_out = false  # Boolean to track fade-out state
var current_animation = ""  # Track the current animation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player_fade.play("FadeIn")
	current_animation = "FadeIn"
	var modulate_color = modulate
	modulate_color.a = 1.0
	modulate = modulate_color
	pass

func _process(_delta: float) -> void:
	pass
	
func _on_area_2d_area_entered(_area: Area2D):
	# Trigger the fade-out effect only if not already faded out
	if not is_faded_out:
		if current_animation != "FadeOut":
			animation_player_fade.stop()
			animation_player_fade.play("FadeOut")
			current_animation = "FadeOut"
			is_faded_out = true

func _on_area_2d_area_exited(_area: Area2D):
	# Trigger the fade-in effect only if faded out
	if is_faded_out:
		if current_animation != "FadeIn":
			animation_player_fade.stop()
			animation_player_fade.play("FadeIn")
			current_animation = "FadeIn"
			is_faded_out = false
