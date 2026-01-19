extends CharacterBody2D
class_name Player

signal combo_changed(new_count)
signal player_has_died

@export var speed: float = 200.0

@onready var combat_comp = $CombatComponent
@onready var health_comp = $HealthComponent
@onready var regen_comp = $RegenComponent
@onready var move_comp = $MovementComponent

# Knockback
var knockback = Vector2.ZERO
@export var knockback_friction: float = 15.0 # Semakin besar, semakin cepat berhenti terseret

func _ready():
	# Sambungkan sinyal dari komponen ke sinyal Player
	# Jadi alurnya: CombatComp -> Player -> HUD
	combat_comp.combo_changed.connect(_on_combat_combo_changed)
	
	health_comp.died.connect(_on_died)
	health_comp.invincibility_changed.connect(_on_invincibility_changed)
	health_comp.healed.connect(_on_healed)

func _physics_process(delta):
	
	combat_comp.look_at(get_global_mouse_position())
	# Cek input serangan
	if Input.is_action_just_pressed("attack"):
		combat_comp.attack()
	
	if not combat_comp.is_attacking:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		
		# Suruh komponen bergerak sesuai arah input
		move_comp.move(direction)
	
	update_sprite_direction()
	
	var is_moving = velocity.length() > 10.0
	regen_comp.handle_regen_logic(delta, is_moving or combat_comp.is_attacking)

func update_sprite_direction():
	# Cek posisi mouse relatif terhadap player
	var mouse_x = get_global_mouse_position().x
	var player_x = global_position.x
	
	# Jika mouse ada di kiri player, flip sprite
	# Asumsi node sprite bernama 'Sprite2D'
	if mouse_x < player_x:
		$Sprite2D.flip_h = true
		# PENTING: Jika sprite dibalik, posisi CombatComponent mungkin perlu disesuaikan
		# atau biarkan CombatComponent menangani rotasinya sendiri (karena kita pakai look_at)
	else:
		$Sprite2D.flip_h = false

func take_damage(amount):
	regen_comp.reset_regen()
	
	health_comp.damage(amount)


# [LOGIKA MATI] Dipanggil via sinyal
func _on_died():
	# Disable collision
	$CollisionShape2D.set_deferred("disabled", true)
	# Animasi mati / Restart
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

# [VISUAL KEBAL] Dipanggil via sinyal
func _on_invincibility_changed(is_active):
	if is_active:
		modulate.a = 0.5
	else:
		modulate.a = 1.0

func _on_combat_combo_changed(new_count):
	combo_changed.emit(new_count)

func _on_healed(_amount):
	# Efek Visual: Flash Hijau
	modulate = Color.GREEN
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func die():
	health_comp.is_dead = true # PENTING: Kunci status mati agar tidak terpanggil 2x
	print("GAME OVER")
	
	# Matikan collision agar musuh tidak bisa nabrak mayat player lagi
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Safety check: Pastikan Tree masih ada sebelum reload
	if get_tree():
		get_tree().reload_current_scene()

# [BARU] Fungsi untuk menerima dorongan dari musuh
func apply_knockback(source_pos, force):
	move_comp.apply_knockback(source_pos, force)
