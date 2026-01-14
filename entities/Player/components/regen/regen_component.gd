extends Node
class_name RegenComponent

# Komponen ini butuh akses ke HealthComponent untuk menyembuhkan
@export var health_comp: HealthComponent

# Konfigurasi
@export var regen_wait_time: float = 3.0  # Waktu tunggu sebelum mulai regen
@export var regen_amount: int = 1         # Jumlah HP per tik
@export var regen_interval: float = 1.0   # Jeda antar tik (detik)

var idle_timer: float = 0.0
var regen_tick_timer: float = 0.0

func _process(_delta):
	# Jika tidak ada health component, matikan script biar hemat performa
	if not health_comp:
		return
		
	# Jangan regen kalau mati atau darah penuh
	if health_comp.is_dead or health_comp.current_hp >= health_comp.max_hp:
		idle_timer = 0.0
		return

# Fungsi ini dipanggil oleh Player setiap frame untuk melapor situasi
# is_busy = true (sedang gerak/serang), is_busy = false (sedang diam)
func handle_regen_logic(delta, is_busy: bool):
	if is_busy:
		# Jika sibuk, reset semua timer
		idle_timer = 0.0
		regen_tick_timer = 0.0
	else:
		# Jika diam, jalankan timer
		idle_timer += delta
		
		# Jika sudah diam cukup lama
		if idle_timer >= regen_wait_time:
			regen_tick_timer += delta
			
			if regen_tick_timer >= regen_interval:
				health_comp.heal(regen_amount)
				regen_tick_timer = 0.0 # Reset tik
				
# Fungsi pembantu untuk mereset paksa (misal saat kena damage)
func reset_regen():
	idle_timer = 0.0
	regen_tick_timer = 0.0
