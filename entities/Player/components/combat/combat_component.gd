extends Node2D
class_name CombatComponent

# Variabel Combo
signal combo_changed(new_count)       # Sinyal untuk Combo

var combo_count = 0
var is_attacking = false
@onready var hitbox = $Hitbox # Mengambil node Hitbox
@onready var sword_sprite = $Hitbox/Sprite2D

@export var attack_duration = 0.2 # Seberapa lama pedang muncul
var enemies_hit_this_swing = []

func _ready():
	hitbox.monitoring = false       # Matikan deteksi di awal
	hitbox.monitorable = false      # Biar efisien
	sword_sprite.visible = false
	
	# Sambungkan sinyal: Kalau ada yang masuk hitbox, panggil fungsi _on_hit
	hitbox.body_entered.connect(_on_body_entered)

func attack():
	if is_attacking:
		return 
	
	is_attacking = true
	
	# 1. RESET LIST MUSUH
	# Kita kosongkan daftar korban, karena ini serangan baru
	enemies_hit_this_swing.clear()
	
	# 2. NYALAKAN PEDANG (VISUAL & LOGIKA)
	sword_sprite.visible = true 
	
	hitbox.monitoring = true    # Mulai memantau tabrakan
	hitbox.monitorable = true
	
	# 3. CEK MUSUH YANG *SUDAH* NEMPEL DULUAN (Point Blank)
	# Karena sinyal body_entered hanya mendeteksi yang BARU masuk
	for body in hitbox.get_overlapping_bodies():
		_on_body_entered(body)
	
	# 4. TUNGGU DURASI ANIMASI
	# Selama waktu ini, sinyal body_entered akan terus aktif memburu musuh
	await get_tree().create_timer(attack_duration).timeout
	
	# 5. MATIKAN PEDANG
	sword_sprite.visible = false
	hitbox.monitoring = false
	hitbox.monitorable = false
	is_attacking = false
	
	reset_combo_after_delay()

func reset_combo_after_delay():
	var current_combo = combo_count
	await get_tree().create_timer(1.0).timeout
	
	if combo_count == current_combo:
		combo_count = 0
		combo_changed.emit(combo_count)

# FUNGSI EKSEKUTOR DAMAGE
func _on_body_entered(body):
	# Syarat 1: Jangan pukul diri sendiri (Player)
	if body == owner or body == get_parent(): 
		return
		
	# Syarat 2: Musuh ini sudah kena pukul di ayunan ini belum?
	if body in enemies_hit_this_swing:
		return # Kalau sudah, abaikan (biar musuh gak kena 10x damage dalam 1 detik)
	
	# Syarat 3: Pastikan dia musuh (punya HP)
	if body.has_method("take_damage"):
		# --- EKSEKUSI ---
		body.take_damage(1)
		
		if body.has_method("apply_knockback"):
			# Arah knockback dari posisi Player (global_position komponen ini)
			body.apply_knockback(global_position, 400.0) # Sesuaikan force-nya
		
		# Catat musuh ini ke daftar korban
		enemies_hit_this_swing.append(body)
		
		# Update Combo
		combo_count += 1
		combo_changed.emit(combo_count)
