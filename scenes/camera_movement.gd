extends CharacterBody2D

const SPEED = 600.0

func _physics_process(delta):
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction_x = Input.get_axis("ui_left", "ui_right") if (Global.ui == null or !Global.ui.visible) else 0

	if direction_x:
		velocity.x = direction_x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	var direction_y = Input.get_axis("ui_up", "ui_down") if (Global.ui == null or !Global.ui.visible) else 0
	if direction_y:
		velocity.y = direction_y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
