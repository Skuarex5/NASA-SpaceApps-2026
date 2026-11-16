
extends RigidBody3D

# =====================================
# REFERENCIAS
# =====================================

@export_group("Interaccion")
@export var astronauta: CharacterBody3D
@export var camara_astronauta: Camera3D
@export var gestor_inventario: Node

@export_group("Combustible (litros)")
@export_range(1.0, 100000.0) var capacidad_combustible: float = 100.0
@export_range(0.0, 100000.0) var combustible_actual: float = 40.0
@export_range(0.0, 100000.0) var combustible_reserva: float = 200.0
@export_range(0.0, 20.0, 0.01) var consumo_motor: float = 0.45
@export_range(0.0, 20.0, 0.01) var consumo_maniobras: float = 0.12
@export_range(0.0, 30.0, 0.01) var consumo_turbo: float = 2.4
@export_range(0.01, 10.0, 0.01) var combustible_arranque_turbo: float = 0.5

var plan_mision: Dictionary = {}

@export_group("Salud del casco")
@export_range(1.0, 10000.0) var salud_maxima: float = 100.0
@export_range(0.0, 10000.0) var salud_actual: float = 100.0
@export_range(0.0, 100.0, 0.1) var velocidad_minima_dano: float = 2.5
@export_range(0.0, 20.0, 0.1) var dano_por_velocidad: float = 1.5

var _espera_impactos: Dictionary = {}
var _velocidad_anterior := Vector3.ZERO

@export_group("Peso de expedicion (kg)")
@export_range(1.0, 1000000.0) var peso_limite: float = 1500.0
@export_range(0.0, 1000000.0) var peso_vacio: float = 1000.0
@export_range(0.0, 100.0, 0.01) var peso_litro_combustible: float = 1.0


func calcular_peso(peso_herramientas: float) -> float:
	return maxf(peso_vacio, 0) + maxf(peso_herramientas, 0) + (
		maxf(combustible_actual, 0) + maxf(combustible_reserva, 0)
	) * maxf(peso_litro_combustible, 0)


func peso_carga_actual() -> float:
	if is_instance_valid(gestor_inventario):
		var ids: Array[String] = []
		return gestor_inventario.objetos.peso_restante(ids)
	return maxf(float(plan_mision.get("peso_carga_kg", 0)), 0)


func peso_actual() -> float:
	return calcular_peso(peso_carga_actual())


func reparar_nave() -> float:
	var reparado := maxf(salud_maxima - salud_actual, 0)
	salud_actual = salud_maxima
	_actualizar_hud_recursos()
	_actualizar_hud_boost()
	return reparado


func cargar_combustible(cantidad: float) -> float:
	var transferido := minf(maxf(cantidad, 0.0), minf(
		maxf(combustible_reserva, 0.0), maxf(capacidad_combustible - combustible_actual, 0.0)
	))
	combustible_actual += transferido
	combustible_reserva -= transferido
	_actualizar_hud_recursos()
	return transferido

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

@export_group("Camera")
@export var sensibilidad_mouse: float = 0.003
@export var invertir_camara_vertical: bool = false
@export var limite_vertical: float = 70.0

@export_group("Fisicas")
@export var freno_lineal: float = 0.8
@export var freno_angular: float = 4.0

@onready var camara_nave: Camera3D = $Camera3D
@onready var hud_controles: CanvasLayer = $HUDControles
@onready var panel_recursos: PanelContainer = $HUDControles/Recursos
@onready var pestana_recursos: Button = $HUDControles/PestanaRecursos
@onready var texto_salud: Label = $HUDControles/Recursos/Margen/Datos/Salud
@onready var barra_salud: ProgressBar = $HUDControles/Recursos/Margen/Datos/BarraSalud
@onready var texto_combustible: Label = $HUDControles/Recursos/Margen/Datos/Combustible
@onready var barra_combustible: ProgressBar = $HUDControles/Recursos/Margen/Datos/BarraCombustible
@onready var texto_reserva: Label = $HUDControles/Recursos/Margen/Datos/Reserva
@onready var texto_peso: Label = $HUDControles/Recursos/Margen/Datos/Peso
@onready var barra_peso: ProgressBar = $HUDControles/Recursos/Margen/Datos/BarraPeso
@onready var aviso_recursos: Label = $HUDControles/Recursos/Margen/Datos/Aviso

@onready var hud_boost: CanvasLayer = $HUDBoost
@onready var barra_boost: ProgressBar = $HUDBoost/VBoxContainer/BarraBoost
@onready var estado_boost: Label = $HUDBoost/VBoxContainer/BarraBoost/EstadoBoost

var pivote_camara: Node3D
var personaje_visual: Node3D

var pilotando: bool = false
var recursos_ocultos: bool = false
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
	max_contacts_reported = 16
	salud_actual = clampf(salud_actual, 0, salud_maxima)
	hud_controles.hide()
	pestana_recursos.pressed.connect(func(): establecer_recursos_ocultos(not recursos_ocultos))
	establecer_recursos_ocultos(false)
	hud_boost.hide()
	barra_boost.value = 100.0
	estado_boost.text = "BOOST READY [SHIFT]"
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
	_actualizar_hud_recursos()

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
			* (-1.0 if invertir_camara_vertical else 1.0)
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

func _unhandled_input(event: InputEvent) -> void:
	# La entrada se solicita desde el escritorio. Q conserva la salida al pilotar.
	if pilotando and event.is_action_pressed("navegar") and not event.is_echo():
		salir_nave()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	_velocidad_anterior = linear_velocity
	for id in _espera_impactos.keys():
		_espera_impactos[id] -= delta
		if _espera_impactos[id] <= 0:
			_espera_impactos.erase(id)

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
	var usando_turbo := tiempo_boost > 0
	var fraccion_combustible := _consumir_combustible(delta) if salud_actual > 0 else 0.0

	# MOTOR PRINCIPAL
	if absf(avance_actual) > 0.001:

		apply_central_force(
			-global_basis.z
			* avance_actual
			* fuerza_motor
			* fraccion_combustible
		)

	# PROPULSION EXTRA DEL TURBO
	if usando_turbo:

		apply_central_force(
			-global_basis.z
			* fuerza_motor
			* multiplicador_boost
			* fraccion_combustible
		)

	# SUBIR / BAJAR
	if absf(vertical_actual) > 0.001:

		apply_central_force(
			Vector3.UP
			* vertical_actual
			* fuerza_vertical
			* fraccion_combustible
		)

	# GIRAR
	if absf(giro_actual) > 0.001:

		apply_torque(
			Vector3.UP
			* giro_actual
			* fuerza_giro
			* fraccion_combustible
		)
	if combustible_actual <= 0 or salud_actual <= 0:
		tiempo_boost = 0
		avance_actual = 0
		giro_actual = 0
		vertical_actual = 0

	_animar_inclinacion(delta)
	_animar_motores()
	_actualizar_hud_recursos()
	_actualizar_hud_boost()


func _integrate_forces(estado: PhysicsDirectBodyState3D) -> void:
	if not pilotando or salud_actual <= 0:
		return
	# Agrupar los contactos de cada roca evita contar varias caras como varios golpes.
	var impactos: Dictionary = {}
	for i in estado.get_contact_count():
		var cuerpo := estado.get_contact_collider_object(i)
		if not is_instance_valid(cuerpo) or not cuerpo.is_in_group("asteroides"):
			continue
		var id := cuerpo.get_instance_id()
		var normal := (estado.transform.basis * estado.get_contact_local_normal(i)).normalized()
		var velocidad := maxf(-_velocidad_anterior.dot(normal), 0)
		velocidad = maxf(velocidad, estado.get_contact_impulse(i).length() / maxf(mass, 0.001))
		impactos[id] = maxf(float(impactos.get(id, 0)), velocidad)
	for id in impactos:
		_registrar_impacto(id, impactos[id])


func _registrar_impacto(id: int, velocidad: float) -> void:
	if not pilotando or salud_actual <= 0 or _espera_impactos.has(id):
		return
	if velocidad <= velocidad_minima_dano:
		return
	_espera_impactos[id] = 0.75
	var dano := minf((velocidad - velocidad_minima_dano) * dano_por_velocidad, 40.0)
	salud_actual = maxf(salud_actual - dano, 0)
	_actualizar_hud_recursos()


func establecer_recursos_ocultos(ocultar: bool) -> void:
	recursos_ocultos = ocultar
	panel_recursos.visible = not ocultar
	pestana_recursos.text = "‹" if ocultar else "›"
	pestana_recursos.tooltip_text = "Show ship resources" if ocultar else "Hide ship resources"
	pestana_recursos.offset_left = -44.0 if ocultar else panel_recursos.offset_left - 28.0
	pestana_recursos.offset_right = -16.0 if ocultar else panel_recursos.offset_left


func _consumir_combustible(delta: float) -> float:
	var litros_segundo := absf(avance_actual) * consumo_motor
	litros_segundo += (absf(vertical_actual) + absf(giro_actual)) * consumo_maniobras
	if tiempo_boost > 0:
		litros_segundo += consumo_turbo
	var solicitado := maxf(litros_segundo * delta, 0)
	if solicitado <= 0:
		return 1.0 if combustible_actual > 0 else 0.0
	var gastado := minf(maxf(combustible_actual, 0), solicitado)
	combustible_actual = maxf(combustible_actual - gastado, 0)
	return gastado / solicitado


func _actualizar_hud_recursos() -> void:
	if not is_node_ready():
		return
	texto_salud.text = "HULL HEALTH   %.0f / %.0f" % [salud_actual, salud_maxima]
	barra_salud.max_value = salud_maxima
	barra_salud.value = salud_actual
	var color_salud := Color("ff8979") if salud_actual <= salud_maxima * 0.25 else Color("ffbc66") if salud_actual <= salud_maxima * 0.5 else Color("77efbd")
	texto_salud.modulate = color_salud
	barra_salud.modulate = color_salud
	texto_combustible.text = "FUEL\n%.1f / %.1f L" % [combustible_actual, capacidad_combustible]
	barra_combustible.max_value = maxf(capacidad_combustible, 1)
	barra_combustible.value = combustible_actual
	texto_reserva.text = "Onboard reserve: %.1f L" % combustible_reserva
	var total := peso_actual()
	texto_peso.text = "TOTAL WEIGHT\n%.1f / %.1f kg\nItems: %.1f kg" % [total, peso_limite, peso_carga_actual()]
	barra_peso.max_value = maxf(peso_limite, 1)
	barra_peso.value = total
	texto_peso.modulate = Color("ffbc66") if total > peso_limite else Color.WHITE
	if salud_actual <= 0:
		aviso_recursos.text = "Hull disabled: engines offline.\nQ: return inside."
		aviso_recursos.modulate = Color("ff8979")
	elif combustible_actual <= 0:
		aviso_recursos.text = "Out of fuel.\nQ: return inside to refuel."
		aviso_recursos.modulate = Color("ff8979")
	elif combustible_actual <= capacidad_combustible * 0.2:
		aviso_recursos.text = "Low fuel: refuel soon."
		aviso_recursos.modulate = Color("ffbc66")
	elif salud_actual <= salud_maxima * 0.25:
		aviso_recursos.text = "Hull critically damaged."
		aviso_recursos.modulate = Color("ff8979")
	else:
		aviso_recursos.text = ""
	barra_combustible.modulate = aviso_recursos.modulate if combustible_actual <= capacidad_combustible * 0.2 else Color.WHITE


# =====================================
# TURBO
# =====================================

func _activar_boost() -> void:

	# No permitir otro boost
	# hasta terminar la recarga.
	if tiempo_recarga > 0.0 or not pilotando or salud_actual <= 0 or combustible_actual < combustible_arranque_turbo:
		return
	combustible_actual -= combustible_arranque_turbo

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

	if motor.has_method("actualizar_intensidad"):
		motor.call("actualizar_intensidad", intensidad, tiempo_boost > 0)
	else:
		motor.visible = intensidad > 0.05


func _apagar_motores() -> void:

	if motor_izquierdo != null:
		if motor_izquierdo.has_method("apagar"):
			motor_izquierdo.call("apagar")
		motor_izquierdo.hide()

	if motor_derecho != null:
		if motor_derecho.has_method("apagar"):
			motor_derecho.call("apagar")
		motor_derecho.hide()


# =====================================
# ENTRAR A LA NAVE
# =====================================

func entrar_nave() -> void:
	hud_controles.show()
	_actualizar_hud_recursos()
	hud_boost.show()
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
	_velocidad_anterior = Vector3.ZERO
	_espera_impactos.clear()

	freeze = false
	sleeping = false

	camara_nave.make_current()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	print("Nave activada")


# =====================================
# SALIR DE LA NAVE
# =====================================


func _actualizar_hud_boost() -> void:
	if salud_actual <= 0:
		barra_boost.value = 0
		estado_boost.text = "HULL DISABLED"
		return
	if combustible_actual <= 0:
		barra_boost.value = 0
		estado_boost.text = "OUT OF FUEL"
		return

	# Mientras el turbo esta activo:
	# la barra baja de 100 a 0.
	if tiempo_boost > 0.0:
		barra_boost.value = (
			tiempo_boost / maxf(duracion_boost, 0.01)
		) * 100.0

		estado_boost.text = (
			"BOOST ACTIVE: %.1f s" % tiempo_boost
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
			"RECHARGING: %.1f s" % tiempo_recarga
		)

	# Turbo disponible.
	else:
		barra_boost.value = 100.0
		estado_boost.text = "BOOST READY [SHIFT]"

func salir_nave() -> void:
	hud_controles.hide()
	hud_boost.hide()
	pilotando = false

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
