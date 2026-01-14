extends Node2D

# Load scene Enemy agar bisa digandakan (instantiate)
var enemy_scene = preload("res://entities/Enemy/Enemy.tscn") 

func _ready():
	# Ambil referensi node
	var player = $Player
	var hud = $HUD
	
	# Hubungkan Sinyal Player ke Fungsi di HUD
	player.health_comp.health_changed.connect(hud.update_health)
	player.combo_changed.connect(hud.update_combo)
	
	# Update tampilan awal (biar HP bar penuh saat mulai)
	hud.update_health(player.health_comp.current_hp, player.health_comp.max_hp)

func _on_timer_timeout():
	# Membuat instance musuh baru
	var enemy = enemy_scene.instantiate()
	
	# Tentukan posisi spawn acak (misal: area 800x600)
	var x_pos = randf_range(50, 800)
	var y_pos = randf_range(50, 600)
	enemy.position = Vector2(x_pos, y_pos)
	
	# Masukkan musuh ke dalam scene
	add_child(enemy)
