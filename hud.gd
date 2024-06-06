extends CanvasLayer

# References to the progress bars
@onready var health_bar = $HealthBar
@onready var mana_bar = $ManaBar

func _ready():
	if health_bar == null:
		print("HealthBar node not found.")
	if mana_bar == null:
		print("ManaBar node not found.")

func update_health(health: float, max_health: float) -> void:
	if health_bar:
		health_bar.value = health / max_health * 100
	else:
		print("HealthBar not available.")

func update_mana(mana: float, max_mana: float) -> void:
	if mana_bar:
		mana_bar.value = mana / max_mana * 100
	else:
		print("ManaBar not available.")

# Method to update the round counter
func update_round_counter(current_round, total_rounds):
	$RoundCounter.text = "Round: %d / %d" % [current_round, total_rounds]

# Method to update the enemies left counter
func update_enemies_left_counter(enemies_left):
	$EnemiesLeftCounter.text = "Enemies Left: %d" % [enemies_left]
