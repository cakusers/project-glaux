extends Node2D
class_name CombatComponent

# Variabel Combo
signal combo_changed(new_count)       # Sinyal untuk Combo
var combo_count = 0
var is_attacking = false
@onready var hitbox = $Hitbox # Mengambil node Hitbox
@onready var sword_sprite = $Hitbox/Sprite2D

func _ready():
	# Pastikan hitbox mati di awal
	hitbox.monitoring = false
	sword_sprite.visible = false

func attack():
	if is_attacking:
		return # Jangan serang kalau sedang nyerang
	
	is_attacking = true
	
	# 1. TAMPILKAN PEDANG
	sword_sprite.visible = true 
	
	hitbox.monitoring = true
	await get_tree().physics_frame
	
	var bodies = hitbox.get_overlapping_bodies()
	var enemies_hit_this_frame = 0 
	
	for body in bodies:
		# Kita pakai class_name Enemy biar lebih elegan (jika sudah kamu terapkan)
		# Atau pakai body.has_method("take_damage") seperti sebelumnya
		if body.has_method("take_damage") and body != owner:
			body.take_damage(1)
			
			# Logika Knockback
			# Perhatikan: 'global_position' di sini adalah posisi komponen ini (yg nempel di player)
			if body.has_method("apply_knockback"):
				body.apply_knockback(global_position, 500.0)
			
			combo_count += 1 
			enemies_hit_this_frame += 1
	
	if enemies_hit_this_frame > 0:
		# Emit sinyal lokal, nanti Player yang akan meneruskan ke HUD
		combo_changed.emit(combo_count)
	
	await get_tree().create_timer(0.2).timeout
	
	# 2. SEMBUNYIKAN
	sword_sprite.visible = false
	hitbox.monitoring = false
	is_attacking = false
	
	reset_combo_after_delay()

func reset_combo_after_delay():
	var current_combo = combo_count
	await get_tree().create_timer(1.0).timeout
	
	if combo_count == current_combo:
		combo_count = 0
		combo_changed.emit(combo_count)
