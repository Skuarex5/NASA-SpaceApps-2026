
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

@onready var lista_misiones: Control = $PanelMisiones/ListaMisiones

# =====================================
# VARIABLES
# =====================================

var progresos: Dictionary = {}
var activas: Dictionary = {}
var items_misiones: Dictionary = {}


# =====================================
# INICIALIZACION
# =====================================

func _ready() -> void:

	if escena_item == null:
		push_error("Asigna MisionItem.tscn en Escena Item")
		return

	mision_actualizada.connect(_actualizar_item)

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

		items_misiones[mision.id] = item

		# Mostrar los datos
		item.call(
			"configurar",
			mision,
			0,
			activas[mision.id]
		)

	print("Sistema de misiones inicializado")


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
