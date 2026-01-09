extends CharacterBody2D

@export var speed = 100.0
@export var max_hp = 3

var hp = max_hp
var player = null

func _ready():
	# Mencari node pertama yang ada di grup "player"
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Logika sederhana: Jika bersentuhan dengan player, lukai player
		# Kita gunakan get_slide_collision untuk mendeteksi tabrakan fisik
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider.is_in_group("player") and collider.has_method("take_damage"):
				collider.take_damage(1) # Musuh deal 1 damage ke player

func take_damage(amount):
	hp -= amount
	
	# Efek Visual: Flash Merah
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1) # Kembali putih dalam 0.1 detik
	
	if hp <= 0:
		die()

func die():
	# Bisa tambah efek partikel meledak di sini nanti
	queue_free()
