extends CharacterBody2D

@export var speed = 100.0
@export var max_hp = 3

var hp = max_hp
var player = null

var knockback = Vector2.ZERO
@export var knockback_power = 300.0
@export var knockback_friction = 10.0 # Seberapa cepat musuh berhenti terpental

func _ready():
	# Mencari node pertama yang ada di grup "player"
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_friction)
	
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = (direction * speed) + knockback
		move_and_slide()
		
		# Logika sederhana: Jika bersentuhan dengan player, lukai player
		# Kita gunakan get_slide_collision untuk mendeteksi tabrakan fisik
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			# Cek apakah yang ditabrak adalah Player
			if collider.is_in_group("player"):
					# 1. Deal Damage
				if collider.has_method("take_damage"):
					collider.take_damage(1)
				
				# [BARU] 2. Berikan Knockback ke Player
				if collider.has_method("apply_knockback"):
					# Dorong Player menjauh dari posisi Musuh ini
					# Angka 400.0 adalah kekuatan dorong (bisa diatur)
					collider.apply_knockback(global_position, knockback_power)
			
			#if collider.is_in_group("player") and collider.has_method("take_damage"):
				#collider.take_damage(1) # Musuh deal 1 damage ke player

func take_damage(amount):
	hp -= amount
	
	# Efek Visual: Flash Merah
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1) # Kembali putih dalam 0.1 detik
	
	if hp <= 0:
		die()

# [BARU] Fungsi untuk menerima dorongan
func apply_knockback(source_position, force_amount):
	# Hitung arah: Dari PENYERANG (Player) menuju KORBAN (Enemy)
	var direction = (global_position - source_position).normalized()
	
	# Set knockback vector
	knockback = direction * force_amount

func die():
	# Bisa tambah efek partikel meledak di sini nanti
	queue_free()
