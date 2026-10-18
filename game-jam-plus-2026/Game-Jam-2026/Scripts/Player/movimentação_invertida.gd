extends CharacterBody3D

# --- PLANO DE MOVIMENTAÇÃO 2.5D ---
const FIXED_Z: float = 9.0  # Trava o personagem estritamente no eixo Z do seu mapa

# --- MOVIMENTO E PULO ---
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAX_JUMPS = 2
var jump_count = 0

# --- DASH ---
const DASH_SPEED = 18.0
const DASH_DURATION = 0.2
const DASH_COOLDOWN = 0.5
var is_dashing = false
var has_dashed_in_air = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector3.RIGHT

# --- COMBATE & PARRY ---
var weapon_level: int = 1
var base_damage: float = 10.0

var combo_count: int = 0
const MAX_COMBO: int = 3
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.8

var is_attacking: bool = false
var attack_timer: float = 0.0
const ATTACK_DURATION: float = 0.25

var is_parrying: bool = false
var parry_timer: float = 0.0
const PARRY_DURATION: float = 0.3
var parry_delay_timer: float = 0.0
const PARRY_ATTACK_DELAY: float = 0.15

# Busca a malha visual automaticamente para evitar erros de referência de nós
@onready var mesh_node: Node3D = _find_mesh_node()

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Permite subir rampas íngremes (até 50 graus)
	floor_max_angle = deg_to_rad(50.0)
	
	# Mantenha o personagem "colado" no chão ao descer rampas para não quicar
	floor_snap_length = 0.4
	
	# Garante que ele não deslize ao parar em uma rampa
	floor_stop_on_slope = true

func _physics_process(delta: float) -> void:
	# Trava a velocidade no eixo Z para manter no plano 2.5D
	velocity.z = 0.0

	_update_timers(delta)
	
	# LINHA DE DIAGNÓSTICO (Remova depois)
	print("Input X: ", Input.get_axis("move_left", "move_right"), " | No Chão: ", is_on_floor(), " | Pos Z: ", global_position.z)

	# 1. PARRY
	if is_parrying:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	# 2. DASH
	if is_dashing:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.y = 0.0
		move_and_slide()
		return

	# 3. GRAVIDADE E RESET DE PULO/DASH NO CHÃO
	if is_on_floor():
		jump_count = 0
		has_dashed_in_air = false
	else:
		velocity.y -= gravity * delta

	# 4. ENTRADAS DE MOVIMENTO
	var input_x = Input.get_axis("move_left", "move_right")

	if input_x != 0 and not is_attacking:
		dash_direction = Vector3(sign(input_x), 0, 0)
		if mesh_node:
			mesh_node.rotation.y = 0.0 if input_x > 0 else PI

	# PULO
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	# DASH
	if Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown_timer <= 0:
		if is_on_floor() or not has_dashed_in_air:
			is_dashing = true
			dash_timer = DASH_DURATION
			dash_cooldown_timer = DASH_COOLDOWN
			if not is_on_floor():
				has_dashed_in_air = true

	# PARRY
	if InputMap.has_action("parry") and Input.is_action_just_pressed("parry") and is_on_floor() and not is_attacking and not is_dashing:
		is_parrying = true
		parry_timer = PARRY_DURATION
		parry_delay_timer = PARRY_ATTACK_DELAY

	# ATAQUE
	if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
		_try_attack()

	# 5. MOVIMENTAÇÃO NORMAL
	if not is_attacking:
		if input_x != 0:
			velocity.x = input_x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.5)

	# Aplica o movimento considerando a inclinação do terreno
	move_and_slide()

func _try_attack() -> void:
	# REGRAS DE BLOQUEIO DE ATAQUE
	if jump_count >= 2: # Não pode atacar no pulo duplo
		return
	if combo_count >= MAX_COMBO: # Não pode passar do 3º ataque
		return
	if is_parrying or parry_delay_timer > 0: # Não pode atacar durante o Parry ou seu delay
		return
	if is_attacking:
		return

	is_attacking = true
	attack_timer = ATTACK_DURATION
	combo_count += 1
	combo_timer = COMBO_WINDOW
	
	var current_damage = (base_damage * weapon_level) + (combo_count * 2.0)
	print("Ataque ", combo_count, "/", MAX_COMBO, " executado! Dano: ", current_damage)

func _update_timers(delta: float) -> void:
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	if is_parrying:
		parry_timer -= delta
		if parry_timer <= 0:
			is_parrying = false
	if parry_delay_timer > 0:
		parry_delay_timer -= delta
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

func _find_mesh_node() -> Node3D:
	for child in get_children():
		if child is MeshInstance3D:
			return child
	return null

func upgrade_weapon(increase: int = 1) -> void:
	weapon_level += increase
	print("Arma aprimorada no ferreiro! Novo nível: ", weapon_level)
