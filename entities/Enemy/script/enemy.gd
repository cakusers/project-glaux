extends CharacterBody2D
class_name Enemy

# --- COMPONENTS ---
@onready var health_comp = $HealthComponent
@onready var move_comp = $MovementComponent # <--- BARU

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
		
	# 2. HANDLE ATTACK
	check_contact_damage()

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
func attack_target(target: Player):
	if is_attacking: return # Cegah serangan spam
	
	is_attacking = true
	
	# 1. Deal Damage & Knockback
	target.take_damage(damage_amount)
	target.apply_knockback(global_position, attack_knockback_force)
	
	# 2. Musuh Mundur Sedikit (Opsional, biar gak nempel banget)
	# move_comp.apply_knockback(target.global_position, 200.0) 
	
	# 3. Tunggu Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	
	# 4. Selesai Cooldown, boleh kejar lagi
	is_attacking = false


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
