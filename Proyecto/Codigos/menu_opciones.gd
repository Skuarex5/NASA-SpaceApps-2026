extends Control

const RESOLUCIONES = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const FPS = [30, 60, 120, 144, 240, 0]
const CAMPOS_GRAFICOS = ["escala_3d", "msaa", "taa", "sombras", "ssao", "ssr", "glow", "distancia_asteroides"]

var borrador: Dictionary = {}
var controles: Dictionary = {}
var estado: Label
var pestanas: TabContainer
var sincronizando := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 20
	var fondo := ColorRect.new()
	fondo.color = Color(0.005, 0.015, 0.025, 0.94)
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 48
	panel.offset_right = -48
	panel.offset_top = 24
	panel.offset_bottom = -24
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("0c202e")
	estilo.border_color = Color("288a9b")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", estilo)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 12)
	panel.add_child(contenido)
	_etiqueta(contenido, "OPTIONS", 24)
	pestanas = TabContainer.new()
	pestanas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.add_child(pestanas)
	_crear_graficos(_pestana("Graphics"))
	var audio := _pestana("Audio")
	_deslizador(audio, "volumen", "Master volume", 0, 100, 1, "%")
	_deslizador(audio, "musica", "Music", 0, 100, 1, "%")
	_deslizador(audio, "ambiente", "In-game ambience", 0, 100, 1, "%")
	var entrada := _pestana("Controls")
	_deslizador(entrada, "sensibilidad_personaje", "Astronaut camera sensitivity", 0.25, 2.5, 0.05, "x")
	_deslizador(entrada, "sensibilidad_nave", "Ship camera sensitivity", 0.25, 2.5, 0.05, "x")
	_casilla(entrada, "invertir_personaje", "Invert astronaut camera Y-axis")
	_casilla(entrada, "invertir_nave", "Invert ship camera Y-axis")
	_etiqueta(entrada, "Sensitivity controls camera movement while holding the right mouse button.", 14)
	estado = _etiqueta(contenido, "", 14)
	estado.custom_minimum_size.y = 22
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	contenido.add_child(botones)
	_boton(botones, "Restore defaults", _restablecer)
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(espacio)
	_boton(botones, "Cancel / Back", hide)
	_boton(botones, "Apply and save", _aplicar)
	hide()


func abrir() -> void:
	borrador = Ajustes.valores.duplicate(true)
	_sincronizar()
	estado.text = "Changes take effect when you select Apply and save."
	show()
	controles.calidad.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()


func _crear_graficos(padre: VBoxContainer) -> void:
	_opcion(padre, "calidad", "Graphics quality", ["Low", "Medium", "High", "Custom"], [0, 1, 2, 3])
	_opcion(padre, "modo_pantalla", "Display mode", ["Windowed", "Fullscreen", "Exclusive fullscreen"], [0, 3, 4])
	var nombres: Array = []
	for resolucion in RESOLUCIONES:
		nombres.append("%d x %d" % [resolucion.x, resolucion.y])
	_opcion(padre, "resolucion", "Window resolution", nombres, RESOLUCIONES)
	_etiqueta(padre, "Fullscreen uses your monitor resolution. 3D render scale improves performance while keeping menus sharp.", 14)
	_opcion(padre, "vsync", "Vertical sync", ["Off", "On", "Adaptive"], [0, 1, 2])
	_opcion(padre, "fps", "Frame rate limit", ["30", "60", "120", "144", "240", "Unlimited"], FPS)
	_deslizador(padre, "escala_3d", "3D render scale", 0.5, 1.0, 0.05, "%", 100)
	_opcion(padre, "msaa", "Antialiasing MSAA", ["Off", "2x", "4x", "8x"], [0, 1, 2, 3])
	_casilla(padre, "taa", "Temporal antialiasing (TAA)")
	_casilla(padre, "sombras", "Dynamic shadows")
	_casilla(padre, "ssao", "Ambient occlusion (SSAO)")
	_casilla(padre, "ssr", "Screen-space reflections (SSR)")
	_casilla(padre, "glow", "Light bloom (Glow)")
	_deslizador(padre, "distancia_asteroides", "Asteroid draw distance", 600, 2000, 100, "m")


func _cambiar(clave: String, valor: Variant) -> void:
	if sincronizando:
		return
	borrador[clave] = valor
	if clave == "calidad" and int(valor) < 3:
		borrador.merge(Ajustes.PERFILES[int(valor)], true)
	elif clave in CAMPOS_GRAFICOS:
		borrador.calidad = 3
	_sincronizar()
	estado.text = "You have unapplied changes."


func _sincronizar() -> void:
	sincronizando = true
	for clave in controles:
		var control: Control = controles[clave]
		if control is OptionButton:
			var valores: Array = control.get_meta("valores")
			control.select(maxi(valores.find(borrador[clave]), 0))
		elif control is CheckButton:
			control.set_pressed_no_signal(borrador[clave])
		elif control is HSlider:
			control.set_value_no_signal(float(borrador[clave]))
			_actualizar_valor(control, float(borrador[clave]))
	controles.resolucion.disabled = borrador.modo_pantalla != 0
	sincronizando = false


func _aplicar() -> void:
	var resultado := Ajustes.aplicar(borrador)
	borrador = Ajustes.valores.duplicate(true)
	_sincronizar()
	estado.text = "Settings applied and saved." if resultado == OK else "Settings applied, but could not be saved to disk."


func _restablecer() -> void:
	borrador = Ajustes.PREDETERMINADOS.duplicate(true)
	_sincronizar()
	estado.text = "Defaults restored. Select Apply and save to confirm."


func _pestana(nombre: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = nombre
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pestanas.add_child(scroll)
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 14)
	margen.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margen)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)
	return columna


func _fila(padre: Node, titulo: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	padre.add_child(fila)
	var etiqueta := _etiqueta(fila, titulo, 16)
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return fila


func _opcion(padre: Node, clave: String, titulo: String, nombres: Array, valores: Array) -> void:
	var fila := _fila(padre, titulo)
	var opcion := OptionButton.new()
	opcion.custom_minimum_size = Vector2(275, 36)
	for nombre in nombres:
		opcion.add_item(str(nombre))
	opcion.set_meta("valores", valores)
	fila.add_child(opcion)
	controles[clave] = opcion
	opcion.item_selected.connect(func(indice): _cambiar(clave, valores[indice]))


func _casilla(padre: Node, clave: String, titulo: String) -> void:
	var fila := _fila(padre, titulo)
	var casilla := CheckButton.new()
	casilla.custom_minimum_size = Vector2(275, 36)
	fila.add_child(casilla)
	controles[clave] = casilla
	casilla.toggled.connect(func(valor): _cambiar(clave, valor))


func _deslizador(padre: Node, clave: String, titulo: String, minimo: float, maximo: float, paso: float, unidad: String, factor: float = 1) -> void:
	var fila := _fila(padre, titulo)
	var deslizador := HSlider.new()
	deslizador.custom_minimum_size = Vector2(190, 36)
	deslizador.min_value = minimo
	deslizador.max_value = maximo
	deslizador.step = paso
	fila.add_child(deslizador)
	var valor := _etiqueta(fila, "", 15)
	valor.custom_minimum_size.x = 70
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	valor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	deslizador.set_meta("etiqueta", valor)
	deslizador.set_meta("unidad", unidad)
	deslizador.set_meta("factor", factor)
	controles[clave] = deslizador
	deslizador.value_changed.connect(func(numero): _cambiar(clave, numero))


func _actualizar_valor(control: HSlider, numero: float) -> void:
	var valor: Label = control.get_meta("etiqueta")
	var unidad: String = control.get_meta("unidad")
	valor.text = ("%.2f%s" if unidad == "x" else "%.0f %s") % [numero * float(control.get_meta("factor")), unidad]


func _etiqueta(padre: Node, texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	padre.add_child(etiqueta)
	return etiqueta


func _boton(padre: Node, texto: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(150, 40)
	boton.pressed.connect(accion)
	padre.add_child(boton)
