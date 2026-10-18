extends CharacterBody3D

# Configurações de Movimento
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Configurações do Dash
const DASH_SPEED = 20.0
const DASH_DURATION = 0.2
var is_dashing = false
var dash_timer = 0.0
var dash_direction = Vector3.ZERO

# Obter a gravidade das configurações do projeto para manter a consistência
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	# 1. Sistema de Dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false # O dash acabou
		else:
			# Mantém a velocidade do dash na direção escolhida
			velocity.x = dash_direction.x * DASH_SPEED
			velocity.z = dash_direction.z * DASH_SPEED
			velocity.y = 0 # Ignora a gravidade durante o dash
			move_and_slide()
			return # Pula o resto da movimentação normal

	# 2. Sistema de Gravidade (Apenas se não estiver no chão)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 3. Sistema de Pulo
	if Input.is_action_just_pressed("ui_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 4. Captura do Input de Movimento (WASD)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 5. Ativação do Dash (Shift)
	if Input.is_action_just_pressed("dash") and not is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION
		# Se o jogador não estiver se movendo, dá o dash para frente
		if direction == Vector3.ZERO:
			dash_direction = -transform.basis.z.normalized()
		else:
			dash_direction = direction

	# 6. Movimentação Normal (Quando não está dando dash)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
