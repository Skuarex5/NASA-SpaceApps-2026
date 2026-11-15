
extends TextureRect

@export_group("Imagenes")
@export var caja_normal: Texture2D
@export var caja_activa: Texture2D
@export var check_vacio: Texture2D
@export var check_marcado: Texture2D

@onready var check: TextureRect = $Check
@onready var titulo: Label = $CanvasLayer/Titulo
@onready var descripcion: Label = $CanvasLayer/Descripcion
@onready var contador: Label = $CanvasLayer/Contador

@onready var capa_textos: CanvasLayer = $CanvasLayer

func _process(_delta: float) -> void:
	capa_textos.transform = get_global_transform_with_canvas()
	
func configurar(
	mision: DatosMision,
	progreso: int,
	activa: bool
) -> void:

	# Mostrar informacion
	titulo.text = mision.titulo
	descripcion.text = mision.descripcion

	# Mostrar contador
	contador.visible = mision.mostrar_contador
	contador.text = "%d/%d" % [
		progreso,
		mision.objetivo
	]

	# Comprobar si esta completada
	var completada: bool = progreso >= mision.objetivo

	# Cambiar checkbox
	if completada:
		check.texture = check_marcado
	else:
		check.texture = check_vacio

	# Cambiar fondo de la mision
	if activa and not completada:
		texture = caja_activa
	else:
		texture = caja_normal
