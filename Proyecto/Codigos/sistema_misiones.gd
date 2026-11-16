
extends Control

# =====================================
# SEÑALES
# =====================================

signal mision_actualizada(id: String)
signal mision_completada(id: String)

# =====================================
# CONFIGURACION
# =====================================

@export_group("Misiones")
@export var misiones: Array[DatosMision] = []
@export var escena_item: PackedScene

@onready var lista_misiones: Control = $PanelMisiones/ScrollMisiones/ListaMisiones
@onready var panel_misiones: Control = $PanelMisiones
@onready var pestana_misiones: Button = $PestanaMisiones

# =====================================
# VARIABLES
# =====================================

var progresos: Dictionary = {}
var activas: Dictionary = {}
var items_misiones: Dictionary = {}
var margen_final: Control
var misiones_ocultas: bool = false
var posicion_abierta: float
var animacion_panel: Tween


# =====================================
# INICIALIZACION
# =====================================

func _ready() -> void:
	posicion_abierta = panel_misiones.position.x
	pestana_misiones.pressed.connect(func(): establecer_misiones_ocultas(not misiones_ocultas))
	_colocar_panel(posicion_abierta)

	if escena_item == null:
		push_error("Asigna MisionItem.tscn en Escena Item")
		return

	mision_actualizada.connect(_actualizar_item)
	# Un separador al final mantiene margen incluso al bajar hasta la ultima mision.
	margen_final = Control.new()
	margen_final.name = "MargenFinal"
	margen_final.custom_minimum_size.y = 10
	margen_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lista_misiones.add_child(margen_final)

	for mision in misiones:

		if mision == null:
			continue

		if mision.id.is_empty():
			push_warning("Una mision no tiene ID")
			continue

		if progresos.has(mision.id):
			push_warning("ID duplicado: " + mision.id)
			continue

		# Inicializar progreso
		progresos[mision.id] = 0
		activas[mision.id] = mision.disponible_al_inicio

		# Crear caja visual
		var item: Node = escena_item.instantiate()

		lista_misiones.add_child(item)
		lista_misiones.move_child(margen_final, -1)

		items_misiones[mision.id] = item

		# Mostrar los datos
		item.call(
			"configurar",
			mision,
			0,
			activas[mision.id]
		)

	print("Sistema de misiones inicializado")


func establecer_misiones_ocultas(ocultar: bool) -> void:
	misiones_ocultas = ocultar
	pestana_misiones.text = "›" if ocultar else "‹"
	pestana_misiones.tooltip_text = "Show missions" if ocultar else "Hide missions to the left"
	if animacion_panel != null and animacion_panel.is_valid():
		animacion_panel.kill()
	var objetivo := -panel_misiones.size.x * panel_misiones.scale.x if ocultar else posicion_abierta
	animacion_panel = create_tween()
	animacion_panel.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacion_panel.tween_method(_colocar_panel, panel_misiones.position.x, objetivo, 0.22)


func _colocar_panel(posicion_x: float) -> void:
	panel_misiones.position.x = posicion_x
	# La pestana queda accesible aun cuando el panel esta fuera de pantalla.
	pestana_misiones.position = Vector2(
		maxf(0.0, posicion_x + panel_misiones.size.x * panel_misiones.scale.x - 4.0),
		panel_misiones.position.y + 80.0
	)


func crear_expedicion(plan: Dictionary, nombre_destino: String) -> String:
	if escena_item == null or str(plan.get("destino", "")).is_empty():
		return ""
	# Evitar misiones duplicadas al pulsar dos veces el mismo boton.
	for existente in misiones:
		if existente == null or not existente.has_meta("expedicion"):
			continue
		var anterior: Dictionary = existente.get_meta("expedicion")
		if anterior.get("destino") == plan.get("destino") and anterior.get("objetivo") == plan.get("objetivo") and anterior.get("herramientas") == plan.get("herramientas") and anterior.get("llevar_rocky", true) == plan.get("llevar_rocky", true) and not esta_completada(existente.id):
			return existente.id
	var mision := DatosMision.new()
	var numero := 1
	while buscar_mision("expedicion_%d" % numero) != null:
		numero += 1
	mision.id = "expedicion_%d" % numero
	mision.titulo = "Expedition %d: %s" % [numero, nombre_destino]
	var equipo := ", ".join(plan.get("herramientas", []))
	mision.descripcion = "%s. Equipment: %s. Weight: %.1f kg." % [
		plan.get("objetivo", "Travel"), equipo if not equipo.is_empty() else "None", plan.get("peso_kg", 0.0)
	]
	if plan.has("llevar_rocky"):
		mision.descripcion += " Rocky: %s." % ("joining you" if plan.llevar_rocky else "waiting in the ship")
	mision.set_meta("expedicion", plan.duplicate(true))
	misiones.append(mision)
	progresos[mision.id] = 0
	activas[mision.id] = true
	var item := escena_item.instantiate()
	lista_misiones.add_child(item)
	lista_misiones.move_child(margen_final, -1)
	items_misiones[mision.id] = item
	item.call("configurar", mision, 0, true)
	return mision.id


# =====================================
# BUSCAR MISION
# =====================================

func buscar_mision(id: String) -> DatosMision:

	for mision in misiones:
		if mision != null and mision.id == id:
			return mision

	return null


# =====================================
# SUMAR PROGRESO
# =====================================

func sumar_progreso(
	id: String,
	cantidad: int = 1
) -> void:

	var mision := buscar_mision(id)

	if mision == null:
		push_warning("Mision no encontrada: " + id)
		return

	if not esta_activa(id):
		return

	var actual: int = progresos.get(id, 0)

	if actual >= mision.objetivo:
		return

	var nuevo: int = clampi(
		actual + cantidad,
		0,
		mision.objetivo
	)

	progresos[id] = nuevo

	mision_actualizada.emit(id)

	if nuevo >= mision.objetivo:
		mision_completada.emit(id)
		print("MISION COMPLETADA: ", mision.titulo)


# =====================================
# CONSULTAS
# =====================================

func obtener_progreso(id: String) -> int:
	return progresos.get(id, 0)


func esta_activa(id: String) -> bool:
	return activas.get(id, false)


func esta_completada(id: String) -> bool:

	var mision := buscar_mision(id)

	if mision == null:
		return false

	return obtener_progreso(id) >= mision.objetivo


# =====================================
# ACTIVAR MISION
# =====================================

func activar_mision(id: String) -> void:

	if buscar_mision(id) == null:
		return

	activas[id] = true
	mision_actualizada.emit(id)


# =====================================
# ACTUALIZAR INTERFAZ
# =====================================

func _actualizar_item(id: String) -> void:

	if not items_misiones.has(id):
		return

	var mision := buscar_mision(id)

	if mision == null:
		return

	items_misiones[id].call(
		"configurar",
		mision,
		obtener_progreso(id),
		esta_activa(id)
	)
