extends TextureRect

var modelo: RefCounted
var contenedor: String
var indice: int
var icono: TextureRect
var cantidad: Label
var inicial: Label


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	icono = TextureRect.new()
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icono)
	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.offset_left = 12
	icono.offset_top = 12
	icono.offset_right = -12
	icono.offset_bottom = -12
	inicial = Label.new()
	inicial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inicial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inicial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inicial)
	inicial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cantidad = Label.new()
	cantidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cantidad.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	cantidad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cantidad.add_theme_font_size_override("font_size", 11)
	add_child(cantidad)
	cantidad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cantidad.offset_right = -8
	cantidad.offset_bottom = -6
	actualizar()


func actualizar() -> void:
	var objeto: Dictionary = modelo.contenedor(contenedor)[indice]
	icono.texture = objeto.get("icono")
	inicial.text = str(objeto.get("nombre", "")).left(2).to_upper() if icono.texture == null else ""
	cantidad.text = str(objeto.cantidad) if int(objeto.get("cantidad", 0)) > 1 else ""
	tooltip_text = "Slot vacio"
	if not objeto.is_empty():
		tooltip_text = "%s\nCantidad: %d · Peso unitario: %.2f kg" % [objeto.nombre, objeto.cantidad, objeto.peso]
		if not str(objeto.get("planeta", "")).is_empty():
			tooltip_text += "\nOrigen: " + str(objeto.planeta)
		tooltip_text += "\nArrastra para mover o intercambiar."


func _get_drag_data(_posicion: Vector2) -> Variant:
	var datos: Dictionary = modelo.datos_arrastre(contenedor, indice)
	if datos.is_empty():
		return null
	var objeto: Dictionary = modelo.contenedor(contenedor)[indice]
	var vista := VBoxContainer.new()
	var imagen := TextureRect.new()
	imagen.texture = objeto.get("icono")
	imagen.custom_minimum_size = Vector2(48, 48)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vista.add_child(imagen)
	var etiqueta := Label.new()
	etiqueta.text = objeto.nombre
	vista.add_child(etiqueta)
	set_drag_preview(vista)
	return datos


func _can_drop_data(_posicion: Vector2, datos: Variant) -> bool:
	return modelo.puede_mover(datos, contenedor, indice)


func _drop_data(_posicion: Vector2, datos: Variant) -> void:
	modelo.mover(datos, contenedor, indice)
