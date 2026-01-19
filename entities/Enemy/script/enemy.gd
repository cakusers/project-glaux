extends CharacterBody2D
class_name Enemy

# --- COMPONENTS ---
@onready var health_comp = $HealthComponent
@onready var move_comp = $MovementComponent # <--- BARU
@onready var attack_area = $AttackArea

# --- VARIABLES ---
var player: Player = null # Kita pakai Tipe Data 'Player' agar autocompletion jalan

# Konfigurasi Serangan
@export var damage_amount: int = 1
@export var attack_knockback_force: float = 400.0
var is_attacking: bool = false
@export var attack_cooldown: float = 0.3

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# Sambungkan Sinyal
	health_comp.died.connect(_on_died)
	health_comp.damaged.connect(_on_damaged) # Untuk efek visual
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(_delta):
	
	if is_attacking:
		move_comp.move(Vector2.ZERO) # Diam di tempat
		return # Stop script di sini, jangan cek tabrakan lagi
	
	# 1. HANDLE MOVEMENT (Lewat Component)
	if player:
		var direction = (player.global_position - global_position).normalized()
		move_comp.move(direction)
	else:
		move_comp.move(Vector2.ZERO)

# Fungsi logika serangan (Menabrak Player)
func check_contact_damage():
	# Kita cek semua tabrakan fisik saat ini
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Gunakan class_name 'Player' untuk pengecekan yang lebih elegan
		if collider is Player:
			attack_target(collider)

# --- FUNGSI SIGNAL RECEIVER ---
func _on_attack_area_body_entered(body):
	# Jika yang masuk ke area adalah Player, dan kita tidak sedang cooldown
	if body is Player and not is_attacking:
		attack_target(body)
		
func attack_target(target: Player):
	is_attacking = true
	
	# Deal Damage & Knockback
	target.take_damage(damage_amount)
	target.apply_knockback(global_position, attack_knockback_force)
	
	# Tunggu Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	is_attacking = false
	
	# [TAMBAHAN CERDAS]
	# Setelah cooldown selesai, cek lagi apakah Player MASIH ada di dalam area?
	# Kalau masih nempel, pukul lagi!
	var overlapping_bodies = attack_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is Player:
			_on_attack_area_body_entered(body) # Panggil fungsi serangan lagi


# Wrapper agar Player bisa memukul Musuh (PENTING)
func take_damage(amount):
	health_comp.damage(amount)

# Wrapper agar Player bisa mendorong Musuh (PENTING)
func apply_knockback(source_pos, force):
	move_comp.apply_knockback(source_pos, force)

func _on_damaged(amount):
	# Efek Visual Flash Merah
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _on_died():
	# Efek partikel mati bisa ditaruh di sini
	queue_free()
