extends CanvasLayer

@export var astronauta: CharacterBody3D
@export var camara: Camera3D
@export var escritorio: StaticBody3D
@export var nave: RigidBody3D
@export_range(0.5, 10.0, 0.1) var alcance: float = 4.0

var menu_abierto: bool = false
var modo_mouse_anterior: int
var aviso: CenterContainer
var menu: Control


func _ready() -> void:
	# Solo esta interfaz sigue funcionando mientras el juego esta pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	aviso = CenterContainer.new()
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	aviso.offset_top = -64
	aviso.offset_bottom = -24
	var opciones := HBoxContainer.new()
	opciones.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opciones.add_theme_constant_override("separation", 20)
	aviso.add_child(opciones)
	_crear_opcion(opciones, "res://Proyecto/Texturas/InteraccionEscritorio/Q.png", "Manejar nave")
	_crear_opcion(opciones, "res://Proyecto/Texturas/InteraccionEscritorio/E.png", "Planificar ruta")
	aviso.hide()

	menu = preload("res://Proyecto/Escenas/Planificador.tscn").instantiate()
	add_child(menu)
	menu.cerrar_solicitado.connect(_cerrar_menu)


func _crear_opcion(fila: HBoxContainer, imagen: String, texto: String) -> void:
	var opcion := HBoxContainer.new()
	opcion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opcion.add_theme_constant_override("separation", 4)
	fila.add_child(opcion)
	var icono := TextureRect.new()
	icono.texture = load(imagen)
	icono.custom_minimum_size = Vector2(40, 40)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opcion.add_child(icono)
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 16)
	etiqueta.add_theme_color_override("font_shadow_color", Color.BLACK)
	etiqueta.add_theme_constant_override("shadow_offset_x", 2)
	etiqueta.add_theme_constant_override("shadow_offset_y", 2)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opcion.add_child(etiqueta)


func _physics_process(_delta: float) -> void:
	aviso.visible = _apunta_al_escritorio()


func _apunta_al_escritorio() -> bool:
	if menu_abierto or get_tree().paused or nave.pilotando or not camara.is_current():
		return false
	# El centro de la pantalla define el objetivo, no la posicion del cursor.
	var centro := get_viewport().get_visible_rect().size * 0.5
	var origen := camara.project_ray_origin(centro)
	var destino := origen + camara.project_ray_normal(centro) * alcance
	var consulta := PhysicsRayQueryParameters3D.create(origen, destino)
	consulta.exclude = [astronauta.get_rid()]
	var impacto := camara.get_world_3d().direct_space_state.intersect_ray(consulta)
	return impacto.get("collider") == escritorio


func _input(event: InputEvent) -> void:
	if not menu_abierto:
		return
	# Consumir acciones del juego; los eventos de mouse siguen hacia la GUI.
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		_cerrar_menu()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not _apunta_al_escritorio():
		return
	if event.is_action_pressed("navegar"):
		astronauta.girando_camara = false
		aviso.hide()
		nave.entrar_nave()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("planificar_ruta"):
		_abrir_menu()
		get_viewport().set_input_as_handled()


func _abrir_menu() -> void:
	modo_mouse_anterior = Input.mouse_mode
	astronauta.girando_camara = false
	menu_abierto = true
	aviso.hide()
	menu.configurar(nave, get_parent().get_node("Planetas"), get_parent().get_node("MissionMenu"), get_parent().get_node("Inventario"))
	menu.abrir()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _cerrar_menu() -> void:
	if not menu_abierto:
		return
	menu_abierto = false
	menu.hide()
	get_tree().paused = false
	# Si se solto el clic derecho en el menu, no dejar la camara capturada.
	astronauta.girando_camara = (
		modo_mouse_anterior == Input.MOUSE_MODE_CAPTURED
		and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	)
	Input.mouse_mode = modo_mouse_anterior if astronauta.girando_camara else Input.MOUSE_MODE_VISIBLE
