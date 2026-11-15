
extends RigidBody3D

# =====================================
# REFERENCIAS
# =====================================

@export_group("Interaccion")
@export var astronauta: CharacterBody3D
@export var camara_astronauta: Camera3D

@export_group("Modelo y motores")
@export var nave_visual: Node3D
@export var motor_izquierdo: Node3D
@export var motor_derecho: Node3D

@export_group("Propulsion")
@export var fuerza_motor: float = 200.0
@export var fuerza_vertical: float = 150.0
@export var fuerza_giro: float = 30.0

@export_group("Turbo Shift")
@export var duracion_boost: float = 5
@export var recarga_boost: float = 25.0
@export var multiplicador_boost: float = 2.5
@export var impulso_boost: float = 10.0

@export_group("Pilotaje")
@export var respuesta_motor: float = 1.8
@export var respuesta_giro: float = 2.5
@export var suavidad_inclinacion: float = 5.0
@export var inclinacion_lateral: float = 15.0
@export var inclinacion_frontal: float = 6.0

@export_group("Camara")
@export var sensibilidad_mouse: float = 0.003
@export var limite_vertical: float = 70.0

@export_group("Fisicas")
@export var freno_lineal: float = 0.8
@export var freno_angular: float = 4.0

@onready var camara_nave: Camera3D = $Camera3D

@onready var hud_boost: CanvasLayer = $HUDBoost
@onready var barra_boost: ProgressBar = $HUDBoost/VBoxContainer/BarraBoost
@onready var estado_boost: Label = $HUDBoost/VBoxContainer/CanvasLayer/EstadoBoost
@onready var capa_texto_boost: CanvasLayer = $HUDBoost/VBoxContainer/CanvasLayer

var pivote_camara: Node3D
var personaje_visual: Node3D

var pilotando: bool = false
var posicion_guardada: Transform3D

var capa_astronauta: int
var mascara_astronauta: int
var capa_nave: int
var mascara_nave: int

var avance_actual: float = 0.0
var giro_actual: float = 0.0
var vertical_actual: float = 0.0

var rotacion_visual_inicial: Vector3

# Temporizadores del turbo
var tiempo_boost: float = 0.0
var tiempo_recarga: float = 0.0


# =====================================
# INICIALIZACION
# =====================================

func _ready() -> void:
	hud_boost.hide()
	capa_texto_boost.hide()
	barra_boost.value = 100.0
	estado_boost.text = "BOOST LISTO [SHIFT]"
	_configurar_estilo_barra()
	gravity_scale = 0.0

	linear_damp_mode = DAMP_MODE_REPLACE
	linear_damp = freno_lineal

	angular_damp_mode = DAMP_MODE_REPLACE
	angular_damp = freno_angular

	axis_lock_angular_x = true
	axis_lock_angular_y = false
	axis_lock_angular_z = true

	capa_nave = collision_layer
	mascara_nave = collision_mask

	# Nave inicialmente invisible
	freeze = true
	collision_layer = 0
	collision_mask = 0
	hide()

	if astronauta == null:
		push_error("Asigna Astronauta")
		set_physics_process(false)
		return

	if camara_astronauta == null:
		push_error("Asigna Camara Astronauta")
		set_physics_process(false)
		return

	if nave_visual == null:
		push_error("Asigna Nave Visual")
		set_physics_process(false)
		return

	if camara_nave == null:
		push_error("No se encontro Camera3D")
		set_physics_process(false)
		return

	personaje_visual = astronauta.get_parent() as Node3D

	if personaje_visual == null:
		push_error("No se encontro la raiz del astronauta")
		set_physics_process(false)
		return

	capa_astronauta = astronauta.collision_layer
	mascara_astronauta = astronauta.collision_mask

	rotacion_visual_inicial = nave_visual.rotation

	# Crear pivote de camara automaticamente
	_configurar_camara()

	_apagar_motores()

	print("Sistema de nave inicializado")


# =====================================
# CAMARA CON CLIC DERECHO
# =====================================

func _configurar_camara() -> void:
	pivote_camara = Node3D.new()
	pivote_camara.name = "PivoteCamara"

	add_child(pivote_camara)

	# Conservar la posicion y rotacion
	# local actual de Camera3D.
	camara_nave.reparent(pivote_camara, false)


func _input(event: InputEvent) -> void:

	if not pilotando:
		return

	# Presionar o soltar clic derecho
	if event is InputEventMouseButton:

		var boton: InputEventMouseButton = event

		if boton.button_index == MOUSE_BUTTON_RIGHT:

			if boton.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Girar camara mientras se mantiene
	# presionado el boton derecho.
	if event is InputEventMouseMotion:

		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return

		var movimiento: InputEventMouseMotion = event

		pivote_camara.rotation.y -= (
			movimiento.screen_relative.x
			* sensibilidad_mouse
		)

		pivote_camara.rotation.x -= (
			movimiento.screen_relative.y
			* sensibilidad_mouse
		)

		var limite: float = deg_to_rad(limite_vertical)

		pivote_camara.rotation.x = clampf(
			pivote_camara.rotation.x,
			-limite,
			limite
		)


# =====================================
# FISICAS Y CONTROLES
# =====================================

func _physics_process(delta: float) -> void:

	# Actualizar temporizadores siempre,
	# incluso cuando estamos fuera de la nave.
	tiempo_boost = maxf(
		0.0,
		tiempo_boost - delta
	)

	tiempo_recarga = maxf(
		0.0,
		tiempo_recarga - delta
	)
	
	_actualizar_hud_boost()
	
	# Q PARA ENTRAR O SALIR
	if Input.is_action_just_pressed("navegar"):

		if pilotando:
			salir_nave()
		else:
			entrar_nave()

		return

	if not pilotando:
		return

	# ACTIVAR TURBO CON SHIFT
	if Input.is_action_just_pressed("correr"):
		_activar_boost()

	# CONTROLES
	var avance: float = (
		Input.get_action_strength("mover_adelante")
		- Input.get_action_strength("mover_atras")
	)

	var giro: float = (
		Input.get_action_strength("mover_izquierda")
		- Input.get_action_strength("mover_derecha")
	)

	var vertical: float = (
		Input.get_action_strength("saltar")
		- Input.get_action_strength("nave_bajar")
	)

	# Suavizar controles
	avance_actual = move_toward(
		avance_actual,
		avance,
		respuesta_motor * delta
	)

	giro_actual = move_toward(
		giro_actual,
		giro,
		respuesta_giro * delta
	)

	vertical_actual = move_toward(
		vertical_actual,
		vertical,
		respuesta_motor * delta
	)

	# MOTOR PRINCIPAL
	if absf(avance_actual) > 0.001:

		apply_central_force(
			-global_basis.z
			* avance_actual
			* fuerza_motor
		)

	# PROPULSION EXTRA DEL TURBO
	if tiempo_boost > 0.0:

		apply_central_force(
			-global_basis.z
			* fuerza_motor
			* multiplicador_boost
		)

	# SUBIR / BAJAR
	if absf(vertical_actual) > 0.001:

		apply_central_force(
			Vector3.UP
			* vertical_actual
			* fuerza_vertical
		)

	# GIRAR
	if absf(giro_actual) > 0.001:

		apply_torque(
			Vector3.UP
			* giro_actual
			* fuerza_giro
		)

	_animar_inclinacion(delta)
	_animar_motores()


# =====================================
# TURBO
# =====================================

func _activar_boost() -> void:

	# No permitir otro boost
	# hasta terminar la recarga.
	if tiempo_recarga > 0.0:
		return

	tiempo_boost = duracion_boost
	tiempo_recarga = recarga_boost

	# Aceleracion inmediata inicial.
	apply_central_impulse(
		-global_basis.z * impulso_boost
	)

	print("TURBO ACTIVADO")


# =====================================
# INCLINACION DE LA NAVE
# =====================================

func _animar_inclinacion(delta: float) -> void:

	# Inclinacion frontal
	var objetivo_x: float = (
		rotacion_visual_inicial.x
		+ deg_to_rad(inclinacion_frontal)
		* avance_actual
	)

	# Inclinacion lateral corregida
	var objetivo_z: float = (
		rotacion_visual_inicial.z
		- deg_to_rad(inclinacion_lateral)
		* giro_actual
	)

	var suavizado: float = (
		1.0 - exp(-suavidad_inclinacion * delta)
	)

	nave_visual.rotation.x = lerp_angle(
		nave_visual.rotation.x,
		objetivo_x,
		suavizado
	)

	nave_visual.rotation.z = lerp_angle(
		nave_visual.rotation.z,
		objetivo_z,
		suavizado
	)


# =====================================
# MOTORES DE FUEGO
# =====================================

func _animar_motores() -> void:

	var intensidad: float = maxf(
		absf(avance_actual),
		maxf(
			absf(vertical_actual),
			absf(giro_actual) * 0.5
		)
	)

	# Mantener los motores encendidos
	# durante todo el turbo.
	if tiempo_boost > 0.0:
		intensidad = 1.0

	_actualizar_motor(
		motor_izquierdo,
		intensidad
	)

	_actualizar_motor(
		motor_derecho,
		intensidad
	)


func _actualizar_motor(
	motor: Node3D,
	intensidad: float
) -> void:

	if motor == null:
		return

	motor.visible = intensidad > 0.05


func _apagar_motores() -> void:

	if motor_izquierdo != null:
		motor_izquierdo.hide()

	if motor_derecho != null:
		motor_derecho.hide()


# =====================================
# ENTRAR A LA NAVE
# =====================================

func entrar_nave() -> void:
	hud_boost.show()
	capa_texto_boost.show()
	posicion_guardada = astronauta.global_transform
	
	pilotando = true

	astronauta.velocity = Vector3.ZERO

	astronauta.set_physics_process(false)
	astronauta.set_process_input(false)
	astronauta.set_process_unhandled_input(false)

	astronauta.collision_layer = 0
	astronauta.collision_mask = 0

	personaje_visual.hide()

	# Nave en su ultima posicion
	show()

	collision_layer = capa_nave
	collision_mask = mascara_nave

	avance_actual = 0.0
	giro_actual = 0.0
	vertical_actual = 0.0

	freeze = false
	sleeping = false

	camara_nave.make_current()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	print("Nave activada")


# =====================================
# SALIR DE LA NAVE
# =====================================


func _actualizar_hud_boost() -> void:

	# Mientras el turbo esta activo:
	# la barra baja de 100 a 0.
	if tiempo_boost > 0.0:
		barra_boost.value = (
			tiempo_boost / maxf(duracion_boost, 0.01)
		) * 100.0

		estado_boost.text = (
			"TURBO ACTIVO: %.1f s" % tiempo_boost
		)

	# Durante la recarga:
	# la barra vuelve a llenarse.
	elif tiempo_recarga > 0.0:
		var tiempo_recuperacion: float = maxf(
			recarga_boost - duracion_boost,
			0.01
		)

		var progreso: float = clampf(
			1.0 - tiempo_recarga / tiempo_recuperacion,
			0.0,
			1.0
		)

		barra_boost.value = progreso * 100.0

		estado_boost.text = (
			"RECARGANDO: %.1f s" % tiempo_recarga
		)

	# Turbo disponible.
	else:
		barra_boost.value = 100.0
		estado_boost.text = "BOOST LISTO [SHIFT]"

func salir_nave() -> void:
	hud_boost.hide()
	pilotando = false
	capa_texto_boost.hide()

	# Desactivar turbo si estaba activo.
	# La recarga continua igualmente.
	tiempo_boost = 0.0

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Conservar posicion de la nave
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	collision_layer = 0
	collision_mask = 0

	_apagar_motores()

	nave_visual.rotation = rotacion_visual_inicial

	# Restaurar orientacion de camara
	pivote_camara.rotation = Vector3.ZERO

	# Volver a la ultima posicion del astronauta
	astronauta.global_transform = posicion_guardada
	astronauta.velocity = Vector3.ZERO

	astronauta.collision_layer = capa_astronauta
	astronauta.collision_mask = mascara_astronauta

	personaje_visual.show()

	astronauta.set_physics_process(true)
	astronauta.set_process_input(true)
	astronauta.set_process_unhandled_input(true)

	camara_astronauta.make_current()

	hide()

	print("Nave desactivada")


func _configurar_estilo_barra() -> void:
	# Fondo oscuro redondeado
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#001e2e")
	fondo.set_corner_radius_all(10)
	fondo.corner_detail = 12
	fondo.anti_aliasing = true

	# Relleno naranja redondeado
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color("#0a94da")
	relleno.set_corner_radius_all(10)
	relleno.corner_detail = 12
	relleno.anti_aliasing = true

	barra_boost.add_theme_stylebox_override(
		"background", fondo
	)

	barra_boost.add_theme_stylebox_override(
		"fill", relleno
	)
