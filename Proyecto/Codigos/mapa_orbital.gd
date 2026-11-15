extends Control

var nave: Node3D
var planetas: Array[Node3D] = []
var destino: Node3D
var camara: Camera3D
var captura: SubViewport
var arrastrando := false
var indicadores: Control


func _ready() -> void:
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	var pantalla := SubViewportContainer.new()
	pantalla.stretch = true
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pantalla)
	pantalla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	captura = SubViewport.new()
	captura.handle_input_locally = false
	captura.world_3d = get_viewport().world_3d
	captura.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	pantalla.add_child(captura)
	camara = Camera3D.new()
	camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	camara.near = 0.1
	camara.far = 400000.0
	# El cielo panoramico se deforma con una camara ortogonal.
	camara.environment = Environment.new()
	camara.environment.background_mode = Environment.BG_COLOR
	camara.environment.background_color = Color("07121d")
	captura.add_child(camara)
	camara.rotation_degrees = Vector3(-90, 0, 0)
	camara.current = true
	indicadores = Control.new()
	indicadores.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(indicadores)
	indicadores.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	indicadores.draw.connect(_dibujar_indicadores)
	gui_input.connect(_manejar_mapa)
	reencuadrar()


func reencuadrar() -> void:
	if camara == null or nave == null:
		return
	var minimo := nave.global_position
	var maximo := minimo
	for planeta in planetas:
		minimo = minimo.min(planeta.global_position)
		maximo = maximo.max(planeta.global_position)
	var centro := (minimo + maximo) * 0.5
	camara.global_position = Vector3(centro.x, maximo.y + 100000.0, centro.z)
	var aspecto := maxf(size.x / maxf(size.y, 1.0), 0.1)
	camara.size = maxf(maxf(maximo.x - minimo.x, (maximo.z - minimo.z) * aspecto) * 1.8, 1000.0)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		indicadores.queue_redraw()


func _manejar_mapa(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			arrastrando = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var factor := 0.85 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 0.85
			camara.size = clampf(camara.size * factor, 50.0, 200000.0)
		accept_event()
	elif event is InputEventMouseMotion:
		# Consultar el boton evita que el arrastre quede activo al soltar fuera del mapa.
		if arrastrando and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var escala := camara.size / maxf(size.x, 1.0)
			camara.position.x -= event.relative.x * escala
			camara.position.z -= event.relative.y * escala
		accept_event()


func _proyectar(posicion: Vector3) -> Vector2:
	var dimensiones := Vector2(captura.size)
	return camara.unproject_position(posicion) * size / dimensiones.max(Vector2.ONE)


func _dibujar_indicadores() -> void:
	if camara == null or nave == null:
		return
	var origen := _proyectar(nave.global_position)
	for x in range(0, int(size.x), 40):
		indicadores.draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.1, 0.4, 0.5, 0.15))
	for y in range(0, int(size.y), 40):
		indicadores.draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.1, 0.4, 0.5, 0.15))
	if is_instance_valid(destino):
		var llegada := _proyectar(destino.global_position)
		indicadores.draw_dashed_line(origen, llegada, Color("46e5eb"), 2.0, 10.0)
	for planeta in planetas:
		_dibujar_marcador(_proyectar(planeta.global_position), str(planeta.name), Color("90cddf"))
	_dibujar_marcador(origen, "NAVE", Color("ffce70"))


func _dibujar_marcador(punto: Vector2, texto: String, color: Color) -> void:
	indicadores.draw_arc(punto, 10, 0, TAU, 32, color, 2.0, true)
	indicadores.draw_circle(punto, 3, color)
	indicadores.draw_string(ThemeDB.fallback_font, punto + Vector2(16, -12), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
