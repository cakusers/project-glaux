extends Node2D

# Load scene Enemy agar bisa digandakan (instantiate)
var enemy_scene = preload("res://Enemy/Enemy.tscn") 

func _on_timer_timeout():
	# Membuat instance musuh baru
	var enemy = enemy_scene.instantiate()
	
	# Tentukan posisi spawn acak (misal: area 800x600)
	var x_pos = randf_range(50, 800)
	var y_pos = randf_range(50, 600)
	enemy.position = Vector2(x_pos, y_pos)
	
	# Masukkan musuh ke dalam scene
	add_child(enemy)
