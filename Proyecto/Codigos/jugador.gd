
extends CharacterBody3D

@export_group("Movimiento")
@export var velocidad_caminar: float = 1.5
@export var velocidad_correr: float = 3
@export var aceleracion: float = 8.0
@export var desaceleracion: float = 9.0
@export var control_aire: float = 2.0
@export var velocidad_rotacion: float = 8.0

@export_group("Gravedad espacial")
@export var gravedad_espacial: float = 3.0
@export var gravedad_descenso: float = 2.0
@export var velocidad_maxima_caida: float = 5.0

@export_group("Salto")
@export var fuerza_salto: float = 5.5
@export_range(0.0, 2.0, 0.01)
var tiempo_preparacion_salto: float = 0.6

@export_group("Animaciones")
@export var velocidad_transicion_animacion: float = 6.0

@export_group("Camara")
@export var sensibilidad_mouse: float = 0.003
@export var invertir_camara_vertical: bool = true

@onready var modelo: Node3D = $Model
@onready var camera_pivot: Node3D = $Camera
@onready var camara: Camera3D = $Camera/Camera3D
@onready var anim_tree: AnimationTree = $AnimationTree

var animacion: AnimationNodeStateMachinePlayback
var velocidad_animacion: float = 0.0

var girando_camara: bool = false

var preparando_salto: bool = false
var tiempo_salto: float = 0.0
var salto_en_aire: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	anim_tree.active = true
	animacion = anim_tree.get("parameters/playback")
	animacion.start("Locomotion")


func _input(event: InputEvent) -> void:
	# CAMARA SOLO CON CLICK DERECHO
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			girando_camara = event.pressed

			if girando_camara:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("ui_cancel"):
		girando_camara = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseMotion and girando_camara:
		# ROTACION HORIZONTAL
		camera_pivot.rotation.y -= (
			event.relative.x * sensibilidad_mouse
		)

		# ROTACION VERTICAL
		var movimiento_vertical: float = (
			event.relative.y * sensibilidad_mouse
		)

		if invertir_camara_vertical:
			camera_pivot.rotation.x += movimiento_vertical
		else:
			camera_pivot.rotation.x -= movimiento_vertical

		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(-60),
			deg_to_rad(45)
		)


func _physics_process(delta: float) -> void:
	var en_suelo: bool = is_on_floor()

	# INICIAR PREPARACION DEL SALTO
	if Input.is_action_just_pressed("saltar"):
		if en_suelo and not preparando_salto and not salto_en_aire:
			preparando_salto = true
			tiempo_salto = 0.0

			# INICIAR ANIMACION JUMP
			animacion.travel("Jump")

	# PREPARACION ANTES DEL DESPEGUE
	if preparando_salto:
		tiempo_salto += delta

		if tiempo_salto >= tiempo_preparacion_salto:
			preparando_salto = false
			salto_en_aire = true

			# IMPULSO VERTICAL
			velocity.y = fuerza_salto

	# GRAVEDAD ESPACIAL
	if not en_suelo:
		var gravedad_actual: float = gravedad_espacial

		# DESCENSO MAS LENTO
		if velocity.y < 0.0:
			gravedad_actual = gravedad_descenso

		velocity.y -= gravedad_actual * delta

		# LIMITAR VELOCIDAD DE CAIDA
		velocity.y = maxf(
			velocity.y,
			-velocidad_maxima_caida
		)

	elif not salto_en_aire:
		velocity.y = 0.0

	# CONTROLES WASD
	var entrada: Vector2 = Input.get_vector(
		"mover_izquierda",
		"mover_derecha",
		"mover_adelante",
		"mover_atras"
	)

	# DIRECCION RELATIVA A LA CAMARA
	var direccion: Vector3 = camara.global_basis * Vector3(
		entrada.x,
		0.0,
		entrada.y
	)

	direccion.y = 0.0
	direccion = direccion.normalized()

	# CAMINAR O CORRER
	var velocidad_objetivo: float = velocidad_caminar

	if Input.is_action_pressed("correr"):
		velocidad_objetivo = velocidad_correr

	var movimiento_objetivo: Vector3 = (
		direccion * velocidad_objetivo
	)

	# ACELERACION Y DESACELERACION
	var aceleracion_actual: float = aceleracion

	if entrada.length() < 0.1:
		aceleracion_actual = desaceleracion

	# MENOR CONTROL EN EL AIRE
	if not en_suelo:
		aceleracion_actual = control_aire

	velocity.x = move_toward(
		velocity.x,
		movimiento_objetivo.x,
		aceleracion_actual * delta
	)

	velocity.z = move_toward(
		velocity.z,
		movimiento_objetivo.z,
		aceleracion_actual * delta
	)

	# ROTACION SUAVE DEL PERSONAJE
	if direccion.length() > 0.1:
		var angulo: float = atan2(
			direccion.x,
			direccion.z
		)

		modelo.rotation.y = lerp_angle(
			modelo.rotation.y,
			angulo,
			minf(velocidad_rotacion * delta, 1.0)
		)

	# APLICAR MOVIMIENTO FISICO
	move_and_slide()

	# DETECTAR ATERRIZAJE
	if salto_en_aire and is_on_floor():
		salto_en_aire = false
		tiempo_salto = 0.0

	# ACTUALIZAR ANIMACIONES
	actualizar_animaciones(delta)



func actualizar_animaciones(delta: float) -> void:
	var velocidad_horizontal: float = Vector2(
		velocity.x,
		velocity.z
	).length()

	var entrada: Vector2 = Input.get_vector(
		"mover_izquierda",
		"mover_derecha",
		"mover_adelante",
        "mover_atras"
	)

	var mezcla_objetivo: float = 0.0

	# Mezclar Idle y Walking segun la velocidad
	mezcla_objetivo = clampf(
		velocidad_horizontal / maxf(velocidad_caminar, 0.01),
		0.0,
		1.0
	)

	# Pasar progresivamente a Running
	if Input.is_action_pressed("correr") and entrada.length() > 0.1:
		if velocidad_horizontal > velocidad_caminar:
			mezcla_objetivo = 1.0 + 2.0 * clampf(
				(velocidad_horizontal - velocidad_caminar)
				/ maxf(velocidad_correr - velocidad_caminar, 0.01),
				0.0,
				1.0
			)

	# Suavizar la transicion
	velocidad_animacion = move_toward(
		velocidad_animacion,
		mezcla_objetivo,
		velocidad_transicion_animacion * delta
	)

	anim_tree.set(
		"parameters/Locomotion/blend_position",
		velocidad_animacion
	)

	var estado_actual: StringName = animacion.get_current_node()

	if preparando_salto or salto_en_aire or not is_on_floor():
		if estado_actual != &"Jump":
			animacion.travel("Jump")
		return

	if estado_actual != &"Locomotion":
		animacion.travel("Locomotion")
