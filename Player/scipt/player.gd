extends CharacterBody2D

@export var speed: float = 200.0
# Variabel Combo
var combo_count = 0
var is_attacking = false
@onready var hitbox = $Hitbox # Mengambil node Hitbox

@onready var combo_label = $ComboLabel


func _physics_process(_delta):
	# Kita cegah pergerakan saat sedang menyerang agar tidak 'sliding'
	if not is_attacking:
		move_state()
	
	# Cek input serangan
	if Input.is_action_just_pressed("attack") and not is_attacking:
		print('sedang menyerang')
		attack_sequence()

func move_state():
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * speed
		# Opsional: Memutar hitbox mengikuti arah jalan
		# Jika jalan ke kiri, hitbox pindah ke kiri, dst.
		rotation = direction.angle() 
	else:
		velocity = Vector2.ZERO
	move_and_slide()

#func move_state() -> void:
	#var direction = Vector2.ZERO
	#direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	#direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	#velocity = direction.normalized() * SPEED
	#
	#move_and_slide()

func attack_sequence():
	is_attacking = true
	
	# Logika Combo Sederhana
	combo_count += 1
	update_combo_visual()
	
	# Nyalakan Hitbox
	hitbox.monitoring = true
	
	# Kita tunggu 1 frame fisika agar Godot sempat mendeteksi tabrakan
	await get_tree().physics_frame
	
	# Cek apakah ada musuh di dalam hitbox SAAT INI JUGA
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage()
	
	# Durasi serangan (misal 0.2 detik)
	await get_tree().create_timer(0.2).timeout
	
	# Matikan Hitbox dan reset status serang
	hitbox.monitoring = false
	is_attacking = false
	
	# Reset Combo jika pemain diam terlalu lama (mekanik combo reset)
	reset_combo_after_delay()

# --- FUNGSI BARU UNTUK VISUAL ---
func update_combo_visual():
	# Update teks
	combo_label.text = "x" + str(combo_count)
	
	# Animasi sederhana menggunakan Tween (Godot 4)
	var tween = create_tween()
	
	# 1. Pastikan label terlihat (Alpha = 1) dan sedikit membesar
	combo_label.modulate.a = 1.0 
	combo_label.scale = Vector2(1.5, 1.5)
	
	# 2. Animasi mengecil kembali ke ukuran normal (efek "Pop")
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)

func reset_combo_after_delay():
	var current_combo = combo_count
	await get_tree().create_timer(1.0).timeout
	
	# Jika combo tidak bertambah (pemain berhenti nyerang)
	if combo_count == current_combo:
		combo_count = 0
		# Hilangkan label pelan-pelan
		var tween = create_tween()
		tween.tween_property(combo_label, "modulate:a", 0.0, 0.2) # Fade out
