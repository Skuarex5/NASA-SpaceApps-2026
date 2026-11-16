extends CanvasLayer

const MODELO = preload("res://Proyecto/Codigos/contenedores_objetos.gd")
const SLOT = preload("res://Proyecto/Codigos/slot_inventario.gd")

@export var astronauta: CharacterBody3D
@export var nave: RigidBody3D
@export var imagen_slot: Texture2D = preload("res://Proyecto/Texturas/Inventario/Slot.png")

var objetos = MODELO.new(12)
var abierto := false
var interfaz: Control
var aviso: VBoxContainer
var slots: Array[Control] = []
var informacion: Dictionary = {}
var modo_mouse_anterior: int


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 110
	aviso = VBoxContainer.new()
	aviso.add_theme_constant_override("separation", 2)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aviso)
	aviso.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	aviso.position += Vector2(16, -98)
	_crear_aviso_tecla("I", "Backpack")
	_crear_aviso_tecla("F", "Helmet lights")
	interfaz = Control.new()
	add_child(interfaz)
	interfaz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sombra := ColorRect.new()
	sombra.color = Color(0.015, 0.025, 0.04, 0.5)
	interfaz.add_child(sombra)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margen := MarginContainer.new()
	interfaz.add_child(margen)
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 24)
	margen.add_child(fila)
	var espacio := Control.new()
	espacio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(espacio)
	_crear_panel(fila, "mochila", "BACKPACK")
	var instrucciones := Label.new()
	instrucciones.text = "Drag between slots to move, stack or swap items.\nI / Esc: return to game"
	instrucciones.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instrucciones.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interfaz.add_child(instrucciones)
	instrucciones.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	instrucciones.offset_top = -62
	instrucciones.offset_bottom = -12
	var cerrar := Button.new()
	cerrar.text = "Close (I / Esc)"
	cerrar.pressed.connect(cerrar_inventario)
	interfaz.add_child(cerrar)
	cerrar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	cerrar.offset_left = -180
	cerrar.offset_right = -24
	cerrar.offset_top = 20
	cerrar.offset_bottom = 56
	objetos.cambiado.connect(_actualizar)
	_actualizar()
	interfaz.hide()


func _crear_aviso_tecla(tecla: String, texto: String) -> void:
	var fila := HBoxContainer.new()
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_theme_constant_override("separation", 4)
	aviso.add_child(fila)
	var icono := TextureRect.new()
	icono.texture = load("res://Proyecto/Texturas/InteraccionEscritorio/%s.png" % tecla)
	icono.custom_minimum_size = Vector2(40, 40)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(icono)
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 16)
	etiqueta.add_theme_color_override("font_shadow_color", Color.BLACK)
	etiqueta.add_theme_constant_override("shadow_offset_x", 2)
	etiqueta.add_theme_constant_override("shadow_offset_y", 2)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(etiqueta)


func _crear_panel(padre: Node, nombre: String, titulo: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.025, 0.065, 0.1, 0.97)
	estilo.border_color = Color("267583")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", estilo)
	padre.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	panel.add_child(columna)
	var encabezado := Label.new()
	encabezado.text = titulo
	encabezado.add_theme_font_size_override("font_size", 22)
	columna.add_child(encabezado)
	var info := Label.new()
	info.add_theme_font_size_override("font_size", 13)
	columna.add_child(info)
	informacion[nombre] = info
	var grilla := GridContainer.new()
	grilla.columns = 4
	grilla.add_theme_constant_override("h_separation", 8)
	grilla.add_theme_constant_override("v_separation", 8)
	columna.add_child(grilla)
	var textura := AtlasTexture.new()
	textura.atlas = imagen_slot
	textura.region = Rect2(imagen_slot.get_size() * Vector2(0.10, 0.08), imagen_slot.get_size() * Vector2(0.80, 0.80))
	for i in objetos.contenedor(nombre).size():
		var slot := TextureRect.new()
		slot.set_script(SLOT)
		slot.modelo = objetos
		slot.contenedor = nombre
		slot.indice = i
		slot.texture = textura
		grilla.add_child(slot)
		slots.append(slot)


func _process(_delta: float) -> void:
	aviso.visible = not abierto and not get_tree().paused and not nave.pilotando


func _input(event: InputEvent) -> void:
	if event.is_echo() or nave.pilotando:
		return
	if abierto and (event.is_action_pressed("inventario") or event.is_action_pressed("ui_cancel")):
		cerrar_inventario()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventario") and not get_tree().paused:
		abrir_inventario()
		get_viewport().set_input_as_handled()


func abrir_inventario() -> void:
	if abierto or get_tree().paused or nave.pilotando:
		return
	modo_mouse_anterior = Input.mouse_mode
	astronauta.girando_camara = false
	abierto = true
	interfaz.show()
	aviso.hide()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func cerrar_inventario() -> void:
	if not abierto:
		return
	if get_viewport().gui_is_dragging():
		get_viewport().gui_cancel_drag()
	abierto = false
	interfaz.hide()
	get_tree().paused = false
	var capturar := modo_mouse_anterior == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	astronauta.girando_camara = capturar and not nave.pilotando
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capturar else Input.MOUSE_MODE_VISIBLE


func agregar_recurso(id: String, nombre: String, cantidad: int = 1, icono: Texture2D = null, peso: float = 0, planeta: String = "") -> bool:
	# Los recolectables llaman este metodo y se consumen solo si devuelve true.
	return objetos.agregar_recurso(id, nombre, cantidad, icono, peso, planeta)


func _actualizar() -> void:
	for slot in slots:
		slot.actualizar()
	for nombre in informacion:
		var ocupados := 0
		var peso := 0.0
		for objeto in objetos.contenedor(nombre):
			if not objeto.is_empty():
				ocupados += 1
				peso += float(objeto.peso) * int(objeto.cantidad)
		informacion[nombre].text = "%d / 12 slots · %.2f kg" % [ocupados, peso]
