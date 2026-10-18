extends CharacterBody3D

# --- ATRIBUTOS DO INIMIGO ---
@export var max_health: float = 30.0
var current_health: float

@export var speed: float = 2.5
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 1.2

# --- ESTADOS DA IA ---
var target_player: CharacterBody3D = null
var is_player_in_attack_range: bool = false
var can_attack: bool = true
var is_attacking: bool = false

# --- REFERÊNCIAS ---
@onready var health_bar: ProgressBar = $HealthBar3D/SubViewport/ProgressBar if has_node("HealthBar3D/SubViewport/ProgressBar") else null
@onready var mesh_node: Node3D = _find_mesh_node()
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	current_health = max_health
	_update_health_bar()

func _physics_process(delta: float) -> void:
	# Restrição 2.5D: Trava o movimento no eixo Z
	velocity.z = 0.0

	# Aplica Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Movimentação e Perseguição
	if target_player and not is_attacking:
		var direction_x = sign(target_player.global_position.x - global_position.x)
		
		# Vira o modelo visual para a direção do jogador
		if mesh_node and direction_x != 0:
			mesh_node.rotation.y = 0.0 if direction_x > 0 else PI

		if not is_player_in_attack_range:
			velocity.x = direction_x * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			if can_attack:
				_atacar_jogador()
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

# --- COMBATE E ATAQUE ---
func _atacar_jogador() -> void:
	if not target_player or not can_attack:
		return

	is_attacking = true
	can_attack = false
	print("👺 Inimigo Iniciou Ataque!")

	# Tempo do golpe
	await get_tree().create_timer(0.3).timeout

	# Tenta causar dano se o jogador ainda estiver no alcance
	if is_player_in_attack_range and target_player and target_player.has_method("receber_dano"):
		target_player.receber_dano(attack_damage)

	is_attacking = false

	# Tempo de recarga entre ataques
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# --- DANO E BARRA DE VIDA ---
func receber_dano(quantidade: float) -> void:
	current_health -= quantidade
	_update_health_bar()
	print("Inimigo recebeu ", quantidade, " de dano! Vida restante: ", current_health)
	
	if current_health <= 0:
		morrer()

func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = (current_health / max_health) * 100.0

func morrer() -> void:
	queue_free()

func _find_mesh_node() -> Node3D:
	for child in get_children():
		if child is MeshInstance3D:
			return child
	return null

# --- SINAIS DE DETECÇÃO (Conectar no Painel Node) ---
func _on_area_detecao_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		target_player = body

func _on_area_detecao_body_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null

func _on_area_ataque_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_attack_range = true

func _on_area_ataque_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_player_in_attack_range = false
