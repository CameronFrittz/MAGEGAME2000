extends CanvasLayer

func _ready():
	
	$ResumeButton.pressed.connect(_on_ResumeButton_pressed)
	$MainMenuButton.pressed.connect(_on_MainMenuButton_pressed)
	$QuitButton.pressed.connect(_on_QuitButton_pressed)

func _on_ResumeButton_pressed():
	resume_game()

func _on_MainMenuButton_pressed():
	# Optionally change to the main menu scene
	get_tree().change_scene("res://mainmenu.tscn")
	
func _on_QuitButton_pressed():
	get_tree().quit()

# Helper function to resume the game
func resume_game():
	get_tree().paused = false
	queue_free()  # Remove the pause menu from the scene
