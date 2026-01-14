extends Node
class_name MovementComponent

# Kita butuh tahu SIAPA yang digerakkan
@export var character_body: CharacterBody2D

# --- KONFIGURASI ---
@export var speed: float = 200.0
@export var knockback_friction: float = 15.0

# --- STATE ---
var knockback: Vector2 = Vector2.ZERO

func _ready():
	# Jika lupa assign di Inspector, coba cari parentnya otomatis
	if not character_body and get_parent() is CharacterBody2D:
		character_body = get_parent()

func move(direction: Vector2):
	if not character_body: return
	
	# 1. Set Velocity Normal
	character_body.velocity = direction * speed
	
	# 2. Tambahkan Knockback (Fisika)
	# Kurangi knockback perlahan
	knockback = knockback.move_toward(Vector2.ZERO, knockback_friction)
	character_body.velocity += knockback
	
	# 3. Eksekusi Gerakan
	character_body.move_and_slide()

# Fungsi untuk menerima dorongan (Dipanggil saat kena pukul)
func apply_knockback(source_pos: Vector2, force: float):
	if not character_body: return
	
	var direction = (character_body.global_position - source_pos).normalized()
	knockback = direction * force
