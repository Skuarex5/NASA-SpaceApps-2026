extends CanvasLayer

@export var nave: RigidBody3D
@export var viajes: CanvasLayer
@export_range(1.0, 10000.0, 1.0) var salud_maxima: float = 100.0
@export_range(0.0, 10000.0, 0.1) var salud_actual: float = 100.0
@export_range(0.01, 10.0, 0.01) var dano_planeta_por_segundo: float = 0.25
@export_range(0.0, 100.0, 0.1) var recuperacion_cabina_por_segundo: float = 2.0

var panel: PanelContainer
var barra: ProgressBar
var texto: Label
var estado: Label
var relleno: StyleBoxFlat
var evacuando := false


func _ready() -> void:
	layer = 80
	salud_maxima = maxf(salud_maxima, 1.0)
	salud_actual = clampf(salud_actual, 0.0, salud_maxima)
	_crear_interfaz()
	_actualizar_interfaz()


func _crear_interfaz() -> void:
	panel = PanelContainer.new()
	panel.name = "SaludPersonaje"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -252
	panel.offset_right = -20
	panel.offset_top = -100
	panel.offset_bottom = -20
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.02, 0.07, 0.10, 0.92)
	fondo.border_color = Color("2d8292")
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(6)
	fondo.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", fondo)
	var columna := VBoxContainer.new()
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_theme_constant_override("separation", 5)
	panel.add_child(columna)
	texto = Label.new()
	texto.add_theme_font_size_override("font_size", 14)
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(texto)
	barra = ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size.y = 10
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vacio := StyleBoxFlat.new()
	vacio.bg_color = Color("122e39")
	vacio.set_corner_radius_all(3)
	relleno = StyleBoxFlat.new()
	relleno.set_corner_radius_all(3)
	barra.add_theme_stylebox_override("background", vacio)
	barra.add_theme_stylebox_override("fill", relleno)
	columna.add_child(barra)
	estado = Label.new()
	estado.add_theme_font_size_override("font_size", 11)
	estado.add_theme_color_override("font_color", Color("b4ccd2"))
	estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(estado)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(nave) or not is_instance_valid(viajes):
		return
	if get_tree().paused or viajes.estado == viajes.Estado.CARGANDO or evacuando:
		return
	if viajes.estado == viajes.Estado.SUPERFICIE:
		salud_actual = maxf(0.0, salud_actual - dano_planeta_por_segundo * delta)
		if salud_actual <= 0.0:
			# Reservar la transicion antes de diferirla evita dobles despegues con Q.
			evacuando = true
			viajes.estado = viajes.Estado.CARGANDO
			panel.hide()
			_evacuar.call_deferred()
			return
	elif not nave.pilotando:
		salud_actual = minf(salud_maxima, salud_actual + recuperacion_cabina_por_segundo * delta)
	_actualizar_interfaz()


func _actualizar_interfaz() -> void:
	panel.visible = not nave.pilotando and viajes.estado != viajes.Estado.CARGANDO
	var porcentaje := salud_actual / salud_maxima
	var color := Color("ff756c") if porcentaje <= 0.25 else Color("ffbf69") if porcentaje <= 0.5 else Color("71e8b3")
	texto.text = "HEALTH  %.1f / %.0f" % [salud_actual, salud_maxima]
	texto.modulate = color
	relleno.bg_color = color
	barra.max_value = salud_maxima
	barra.value = salud_actual
	if viajes.estado == viajes.Estado.SUPERFICIE:
		estado.text = "Surface exposure  -%.2f HP/s" % dano_planeta_por_segundo
	elif salud_actual < salud_maxima:
		estado.text = "Recovering aboard  +%.1f HP/s" % recuperacion_cabina_por_segundo
	else:
		estado.text = "Safe aboard ship"


func _evacuar() -> void:
	await viajes._despegar(true)
	# La evacuacion estabiliza al astronauta; el resto se recupera en la cabina.
	salud_actual = salud_maxima * 0.25
	evacuando = false
	_actualizar_interfaz()
