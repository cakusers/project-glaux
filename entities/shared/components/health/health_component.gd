extends Node2D
class_name HealthComponent

signal health_changed(current_hp, max_hp) # Lapor ke UI
signal damaged(amount)                    # Lapor untuk efek visual (flash merah)
signal healed(amount)                     # Lapor untuk efek visual (angka hijau)
signal died                               # Lapor bahwa pemiliknya mati
signal invincibility_changed(is_active)   # Lapor status kebal (untuk efek kedip)

# --- CONFIG ---
@export var max_hp: int = 5
@export var has_iframes: bool = false      # Apakah punya fitur kebal? (Player: Ya, Musuh: Mungkin tidak)
@export var iframe_duration: float = 1.0   # Durasi kebal

@onready var timer = $InvincibilityTimer

var current_hp: int
var is_dead: bool = false      
var is_invincible: bool = false

func _ready():
	current_hp = max_hp
	timer.wait_time = iframe_duration
	timer.timeout.connect(_on_timer_timeout)
	
	# Kirim sinyal awal agar UI sync
	health_changed.emit(current_hp, max_hp)

func damage(amount: int):
	# Validasi: Jangan terima damage jika mati atau sedang kebal
	if is_dead or is_invincible:
		return
	
	current_hp -= amount
	current_hp = clampi(current_hp, 0, max_hp) # Pastikan tidak minus
	
	# Emit Sinyal
	health_changed.emit(current_hp, max_hp)
	damaged.emit(amount)
	
	# Cek Mati
	if current_hp <= 0:
		is_dead = true
		died.emit()
	else:
		# Jika belum mati dan fitur iframe aktif, nyalakan invincibility
		if has_iframes:
			start_invincibility()

func heal(amount: int):
	if is_dead: return
	
	current_hp += amount
	current_hp = clampi(current_hp, 0, max_hp)
	
	health_changed.emit(current_hp, max_hp)
	healed.emit(amount)

func start_invincibility():
	is_invincible = true
	invincibility_changed.emit(true) # Beritahu Player untuk kedap-kedip
	timer.start()

func _on_timer_timeout():
	is_invincible = false
	invincibility_changed.emit(false) # Beritahu Player stop kedap-kedip
