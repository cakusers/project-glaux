extends Control

func _on_start_button_pressed() -> void:
	# Pindah ke scene World (Game utama)
	# Pastikan path "res://World.tscn" sesuai dengan nama file scenemu
	get_tree().change_scene_to_file("res://levels/World.tscn")


func _on_quit_button_pressed() -> void:
	# Keluar dari game
	get_tree().quit()
