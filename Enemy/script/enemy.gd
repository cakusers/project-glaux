extends CharacterBody2D

@export var speed = 100.0
var player = null

func _ready():
	# Mencari node pertama yang ada di grup "player"
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player:
		# Hitung arah menuju player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func take_damage():
	# Hapus musuh dari game
	queue_free()
