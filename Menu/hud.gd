extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var combo_label = $ComboLabel

func update_health(hp, max_hp):
	health_bar.max_value = max_hp
	health_bar.value = hp

func update_combo(count):
	combo_label.text = "Combo: " + str(count)
