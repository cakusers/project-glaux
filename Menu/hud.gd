extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var health_label = $HealthBar/HealthLabel
@onready var combo_label = $ComboLabel

# Referensi node baru
@onready var pause_overlay = $PauseOverlay
# Jika path nodenya berbeda, sesuaikan (misal $ColorRect/VBoxContainer/ResumeButton)
@onready var resume_btn = $PauseOverlay/VBoxContainer/ResumeButton
@onready var restart_btn = $PauseOverlay/VBoxContainer/RestartButton
@onready var quit_btn = $PauseOverlay/VBoxContainer/QuitButton
@onready var menu_btn = $MenuButton

func _ready():
	# Sembunyikan menu saat awal game
	pause_overlay.visible = false
	
	# Hubungkan sinyal tombol secara manual (lebih rapi)
	menu_btn.pressed.connect(_on_menu_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func update_health(hp, max_hp):
	health_bar.max_value = max_hp
	health_bar.value = hp
	
	health_label.text = str(hp)

func update_combo(count):
	combo_label.text = "Combo: " + str(count)

func _on_menu_pressed():
	# Tampilkan menu, dan PAUSE game
	pause_overlay.visible = true
	get_tree().paused = true # Waktu berhenti!

func _on_resume_pressed():
	# Sembunyikan menu, dan LANJUTKAN game
	pause_overlay.visible = false
	get_tree().paused = false # Waktu jalan lagi

func _on_restart_pressed():
	# Unpause dulu sebelum reload (Penting! kalau tidak, scene baru akan tetap ter-pause)
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	# Unpause dulu
	get_tree().paused = false
	# Pindah ke Main Menu
	get_tree().change_scene_to_file("res://Menu/MainMenu.tscn")
