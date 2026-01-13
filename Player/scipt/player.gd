extends CharacterBody2D

signal health_changed(new_hp, max_hp) # Sinyal untuk HP
signal combo_changed(new_count)       # Sinyal untuk Combo

@export var speed: float = 200.0
@export var max_hp = 5

# Variabel Combo
var combo_count = 0
var is_attacking = false
@onready var hitbox = $Hitbox # Mengambil node Hitbox
@onready var combo_label = $ComboLabel
@onready var sword_sprite = $Hitbox/Sprite2D

# Variabel HP
var current_hp = max_hp
var is_invincible = false # Status kebal
var is_dead = false

# Regen
@export var regen_wait_time = 1.0  # Harus diam berapa detik sebelum regen mulai?
@export var regen_amount = 1       # Berapa HP yang dipulihkan?
@export var regen_interval = 1.0   # Seberapa cepat HP nambah? (Tiap 1 detik)

var idle_timer = 0.0               # Menghitung berapa lama kita sudah diam
var regen_tick_timer = 0.0         # Menghitung jeda antar penambahan H

# Knockback
var knockback = Vector2.ZERO
@export var knockback_friction = 15.0 # Semakin besar, semakin cepat berhenti terseret

func _physics_process(delta):
	# Kita cegah pergerakan saat sedang menyerang agar tidak 'sliding'
	if not is_attacking:
		move_state()
	
	# Cek input serangan
	if Input.is_action_just_pressed("attack") and not is_attacking:
		print('sedang menyerang')
		attack_sequence()
	
	handle_regeneration(delta)

func move_state():
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction:
		velocity = direction * speed
		# Opsional: Memutar hitbox mengikuti arah jalan
		# Jika jalan ke kiri, hitbox pindah ke kiri, dst.
		hitbox.rotation = direction.angle()
	else:
		velocity = Vector2.ZERO
		
	# [BARU] 2. Tambahkan efek Knockback
	# Kurangi kekuatan knockback setiap frame (efek gesekan)
	knockback = knockback.move_toward(Vector2.ZERO, knockback_friction)
	
	# Gabungkan velocity jalan + velocity terpental
	velocity += knockback
	
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
	sword_sprite.visible = true
	
	# Nyalakan Hitbox
	hitbox.monitoring = true
	
	# Kita tunggu 1 frame fisika agar Godot sempat mendeteksi tabrakan
	await get_tree().physics_frame
	
	var bodies = hitbox.get_overlapping_bodies()
	var enemies_hit_this_frame = 0 # Untuk melacak apakah kita memukul sesuatu

	for body in bodies:
		if body != self and body.has_method("take_damage"):
			body.take_damage(1)
			
			# [BARU] Kirim efek knockback
			if body.has_method("apply_knockback"):
				# Parameter 1: Posisi Player (sumber dorongan)
				# Parameter 2: Kekuatan dorongan (misal 300 - 500)
				body.apply_knockback(global_position, 500.0)
			
			# [BARU] Tambah combo setiap kali loop menemukan musuh
			combo_count += 1 
			enemies_hit_this_frame += 1
			
			combo_changed.emit(combo_count)
	
	if enemies_hit_this_frame > 0:
		update_combo_visual()
	
	# Durasi serangan (misal 0.2 detik)
	await get_tree().create_timer(0.2).timeout
	
	# Matikan Hitbox dan reset status serang
	sword_sprite.visible = false
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
		# [BARU] Lapor ke HUD kalau Combo reset jadi 0
		combo_changed.emit(combo_count)
		
		# Hilangkan label pelan-pelan
		#var tween = create_tween()
		#tween.tween_property(combo_label, "modulate:a", 0.0, 0.2) # Fade out

# --- FUNGSI BARU: MENERIMA DAMAGE DARI MUSUH ---
func take_damage(amount):
	if is_dead or is_invincible:
		return # Jika sedang kebal, abaikan damage
	
	# [BARU] Reset timer regen karena kita baru saja diserang!
	idle_timer = 0.0
	
	current_hp -= amount
	health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		die()
		return
	
	# Aktifkan I-Frames (Kebal sesaat)
	start_invincibility()

func start_invincibility():
	if not is_inside_tree():
		return
	
	is_invincible = true
	# Efek kedap-kedip transparan
	modulate.a = 0.4
	
	# Kebal selama 1 detik
	if get_tree():
		await get_tree().create_timer(1.0).timeout 
	 
	# Kembali normal
	modulate.a = 1.0
	is_invincible = false


func die():
	is_dead = true # PENTING: Kunci status mati agar tidak terpanggil 2x
	print("GAME OVER")
	
	# Matikan collision agar musuh tidak bisa nabrak mayat player lagi
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Safety check: Pastikan Tree masih ada sebelum reload
	if get_tree():
		get_tree().reload_current_scene()

# [BARU] Fungsi untuk menerima dorongan dari musuh
func apply_knockback(source_position, force_amount):
	# Hitung arah dari Musuh menuju Player
	var direction = (global_position - source_position).normalized()
	knockback = direction * force_amount

# Fungsi untuk menyembuhkan player
func heal(amount):
	if is_dead: return # Tidak bisa heal kalau sudah mati
	
	# Tambah HP
	current_hp += amount
	
	# Pastikan tidak melebihi Max HP
	if current_hp > max_hp:
		current_hp = max_hp
	
	# PENTING: Lapor ke HUD agar Health Bar update
	health_changed.emit(current_hp, max_hp)
	
	print("Regen! HP: ", current_hp) # Cek output
	
	# (Opsional) Efek visual healing
	modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func handle_regeneration(delta):
	# Syarat:
	# 1. HP belum penuh
	# 2. Tidak sedang mati
	if current_hp >= max_hp or is_dead:
		idle_timer = 0.0 # Reset biar bersih
		return

	# Cek apakah Player sedang "Sibuk" (Bergerak ATAU Menyerang)
	# velocity.length() > 10.0 artinya sedang bergerak (kita kasih toleransi sedikit biar gak sensitif banget)
	var is_busy = velocity.length() > 10.0 or is_attacking
	
	if is_busy:
		# Jika sibuk, reset timer
		idle_timer = 0.0
		regen_tick_timer = 0.0
	else:
		# Jika diam, jalankan timer
		idle_timer += delta
		
		# Jika sudah diam lebih lama dari batas waktu tunggu
		if idle_timer >= regen_wait_time:
			# Mulai hitung interval per "tik" (misal nambah darah tiap 1 detik)
			regen_tick_timer += delta
			
			if regen_tick_timer >= regen_interval:
				heal(regen_amount)
				regen_tick_timer = 0.0 # Reset tik untuk healing berikutnya
