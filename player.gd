extends CharacterBody2D


const SPEED = 200.0

func _physics_process(delta: float) -> void:
 var direction = Vector2.ZERO
 direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
 direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
 velocity = direction.normalized() * SPEED
 move_and_slide()
