# FreezeReticle.gd
extends Area2D

var freeze_duration: float = 3.5
var spell_activated: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if spell_activated and body.is_in_group("enemies"):
		body.freeze(freeze_duration)

func activate_spell():
	spell_activated = true
