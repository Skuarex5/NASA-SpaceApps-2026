extends CanvasLayer

@export var astronauta: CharacterBody3D
@export var nave: RigidBody3D

var abierto := false
var modo_mouse_anterior: int
var panel: PanelContainer
var opciones: Control
var boton_reanudar: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	var pantalla := Control.new()
	add_child(pantalla)
	pantalla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.005, 0.015, 0.025, 0.82)
	pantalla.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	pantalla.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.custom_minimum_size.x = 380
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("0c202e")
	estilo.border_color = Color("288a9b")
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "PAUSED"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color("77e5ed"))
	columna.add_child(titulo)
	var ayuda := Label.new()
	ayuda.text = "Press P to resume"
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.add_theme_font_size_override("font_size", 14)
	columna.add_child(ayuda)
	boton_reanudar = _boton(columna, "Resume", reanudar)
	_boton(columna, "Settings", _abrir_opciones)
	_boton(columna, "Quit game", _salir)
	opciones = Control.new()
	opciones.set_script(preload("res://Proyecto/Codigos/menu_opciones.gd"))
	pantalla.add_child(opciones)
	opciones.visibility_changed.connect(_cambio_opciones)
	hide()


func _boton(padre: Node, texto: String, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(320, 44)
	boton.add_theme_font_size_override("font_size", 18)
	boton.pressed.connect(accion)
	padre.add_child(boton)
	return boton


func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("pausa"):
		if abierto:
			reanudar()
		else:
			abrir()
		get_viewport().set_input_as_handled()
	elif abierto and event.is_action_pressed("ui_cancel"):
		if opciones.visible:
			opciones.hide()
		else:
			reanudar()
		get_viewport().set_input_as_handled()


func _unhandled_input(_event: InputEvent) -> void:
	if abierto:
		get_viewport().set_input_as_handled()


func abrir() -> void:
	# El planificador, la mochila y las pantallas de carga conservan su propia pausa.
	if abierto or get_tree().paused:
		return
	var viajes := get_parent().get_node_or_null("ViajesPlanetarios")
	if viajes != null and viajes.estado == viajes.Estado.CARGANDO:
		return
	modo_mouse_anterior = Input.mouse_mode
	if is_instance_valid(astronauta):
		astronauta.girando_camara = false
	abierto = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.show()
	show()
	boton_reanudar.grab_focus()


func reanudar() -> void:
	if not abierto:
		return
	abierto = false
	opciones.hide()
	hide()
	get_tree().paused = false
	var capturar := modo_mouse_anterior == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if is_instance_valid(astronauta):
		astronauta.girando_camara = capturar and not (is_instance_valid(nave) and nave.pilotando)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capturar else Input.MOUSE_MODE_VISIBLE


func _abrir_opciones() -> void:
	panel.hide()
	opciones.abrir()


func _cambio_opciones() -> void:
	if abierto and not opciones.visible:
		panel.show()
		boton_reanudar.grab_focus()


func _salir() -> void:
	get_tree().quit()


func _exit_tree() -> void:
	if abierto:
		get_tree().paused = false
