extends Control

signal cerrar_solicitado

const MAPA = preload("res://Proyecto/Codigos/mapa_orbital.gd")

@export_group("Imagenes opcionales")
@export var imagen_fondo: Texture2D
@export var imagen_configuracion: Texture2D
@export var imagen_recursos: Texture2D
@export var imagen_combustible: Texture2D
@export var imagen_herramientas: Texture2D
@export_group("Herramientas disponibles")
@export var herramientas: Array[String] = [
	"Camara", "Radar", "Kit de reparacion", "Oxigeno", "Provisiones",
	"Escaner mineral", "Taladro", "Baliza de senal"
]
@export var imagenes_herramientas: Array[Texture2D] = []
@export var pesos_herramientas: Array[float] = [10.0, 25.0, 15.0, 12.0, 8.0, 6.0, 18.0, 4.0]

var nave: RigidBody3D
var planetas: Array[Node3D] = []
var mapa: Control
var destinos: OptionButton
var objetivos: OptionButton
var combustible: Label
var barra: ProgressBar
var cantidad: SpinBox
var cargar: Button
var salud: Label
var barra_salud: ProgressBar
var reparar: Button
var resumen: Label
var estado: Label
var volver: Button
var seleccion: Array[CheckBox] = []
var sistema_misiones: Node
var peso: Label
var barra_peso: ProgressBar
var confirmar: Button
var inventario: Node


func _ready() -> void:
	_crear_tema()
	var fondo := ColorRect.new()
	fondo.color = Color("08121e")
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if imagen_fondo != null:
		var textura := TextureRect.new()
		textura.texture = imagen_fondo
		textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		textura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		textura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(textura)
		textura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margen := MarginContainer.new()
	add_child(margen)
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 20)
	var estructura := VBoxContainer.new()
	estructura.add_theme_constant_override("separation", 12)
	margen.add_child(estructura)
	_texto(estructura, "PLANIFICADOR DE MISION", 28)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	estructura.add_child(scroll)
	var contenido := VBoxContainer.new()
	contenido.custom_minimum_size = Vector2(1000, 580)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 16)
	scroll.add_child(contenido)
	var columnas := HBoxContainer.new()
	columnas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columnas.add_theme_constant_override("separation", 16)
	contenido.add_child(columnas)
	_crear_configuracion(_panel(columnas, "CONFIGURACION", 240))
	_crear_mapa(_panel(columnas, "MAPA ORBITAL", 420, true))
	_crear_recursos(_panel(columnas, "RECURSOS Y CARGA", 280))
	var pie := _panel(contenido, "", 0)
	resumen = _texto(pie, "", 17)
	estado = _texto(pie, "", 15)
	estado.hide()
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 16)
	pie.add_child(botones)
	confirmar = _boton(botones, "Crear expedicion")
	confirmar.pressed.connect(_guardar_plan)
	volver = _boton(botones, "Volver al juego (Esc)")
	volver.pressed.connect(func(): cerrar_solicitado.emit())
	hide()


func configurar(vehiculo: RigidBody3D, sistema: Node3D, misiones: Node, gestor_inventario: Node = null) -> void:
	nave = vehiculo
	sistema_misiones = misiones
	inventario = gestor_inventario
	planetas.clear()
	if sistema != null:
		for hijo in sistema.get_children():
			if hijo is Node3D:
				planetas.append(hijo)
	destinos.clear()
	for planeta in planetas:
		destinos.add_item(str(planeta.name))
	mapa.nave = nave
	mapa.planetas = planetas
	var plan: Dictionary = nave.plan_mision
	var indice := 0
	for i in planetas.size():
		if str(planetas[i].get_path()) == plan.get("destino", ""):
			indice = i
	if not planetas.is_empty():
		destinos.select(indice)
	objetivos.select(clampi(int(plan.get("objetivo_indice", 0)), 0, objetivos.item_count - 1))
	for i in seleccion.size():
		seleccion[i].set_pressed_no_signal(herramientas[i] in plan.get("herramientas", []))
	estado.text = ""
	estado.hide()
	_actualizar()
	mapa.reencuadrar()


func abrir() -> void:
	show()
	_actualizar()
	# Esperar al layout para encuadrar con la relacion de aspecto definitiva.
	mapa.call_deferred("reencuadrar")
	volver.grab_focus()


func _crear_configuracion(columna: VBoxContainer) -> void:
	_imagen(columna, imagen_configuracion, "Imagen de configuracion", 32)
	_texto(columna, "ORIGEN", 14)
	_texto(columna, "Posicion actual de la nave", 16)
	_texto(columna, "DESTINO", 14)
	destinos = OptionButton.new()
	columna.add_child(destinos)
	destinos.item_selected.connect(func(_i): _actualizar())
	_texto(columna, "OBJETIVO", 14)
	objetivos = OptionButton.new()
	for objetivo in ["Reconocimiento", "Exploracion", "Transporte"]:
		objetivos.add_item(objetivo)
	columna.add_child(objetivos)
	objetivos.item_selected.connect(func(_i): _actualizar())
	_texto(columna, "HERRAMIENTAS A LLEVAR", 14)
	_imagen(columna, imagen_herramientas, "Imagen del equipamiento", 32)
	for i in herramientas.size():
		var fila := HBoxContainer.new()
		columna.add_child(fila)
		var textura: Texture2D = imagenes_herramientas[i] if i < imagenes_herramientas.size() else null
		_imagen(fila, textura, "+", 24, 32)
		var casilla := CheckBox.new()
		casilla.text = "%s (%.1f kg)" % [herramientas[i], _peso_herramienta(i)]
		fila.add_child(casilla)
		seleccion.append(casilla)
		casilla.toggled.connect(func(_valor): _actualizar())


func _crear_mapa(columna: VBoxContainer) -> void:
	mapa = Control.new()
	mapa.set_script(MAPA)
	mapa.custom_minimum_size = Vector2(400, 300)
	mapa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.add_child(mapa)
	_texto(columna, "Arrastrar: mover  |  Rueda: zoom", 14)
	mapa.tooltip_text = "La linea discontinua indica el destino; no representa una trayectoria orbital calculada."
	var centrar := _boton(columna, "Encuadrar nave y planetas")
	centrar.pressed.connect(func(): mapa.reencuadrar())


func _crear_recursos(columna: VBoxContainer) -> void:
	_imagen(columna, imagen_recursos, "Imagen de la nave / recursos", 48)
	_texto(columna, "SALUD DEL CASCO", 18)
	salud = _texto(columna, "", 16)
	barra_salud = ProgressBar.new()
	barra_salud.custom_minimum_size.y = 20
	columna.add_child(barra_salud)
	reparar = _boton(columna, "Reparar nave")
	reparar.tooltip_text = "Mantenimiento a bordo: restaura por completo la salud del casco, sin consumir objetos."
	reparar.pressed.connect(_reparar_nave)
	_texto(columna, "COMBUSTIBLE", 18)
	_imagen(columna, imagen_combustible, "Imagen del combustible", 40)
	combustible = _texto(columna, "", 16)
	barra = ProgressBar.new()
	barra.custom_minimum_size.y = 22
	columna.add_child(barra)
	_texto(columna, "CARGAR DESDE LA RESERVA (L)", 14)
	cantidad = SpinBox.new()
	cantidad.min_value = 0
	cantidad.step = 1
	cantidad.allow_greater = false
	columna.add_child(cantidad)
	cargar = _boton(columna, "Cargar combustible")
	cargar.pressed.connect(_cargar_combustible)
	cargar.tooltip_text = "Transfiere litros de la reserva al tanque sin superar su capacidad."
	_texto(columna, "PESO TOTAL / LIMITE", 18)
	peso = _texto(columna, "", 15)
	barra_peso = ProgressBar.new()
	barra_peso.custom_minimum_size.y = 20
	columna.add_child(barra_peso)


func _actualizar() -> void:
	if nave == null:
		return
	salud.text = "%.1f / %.1f puntos" % [nave.salud_actual, nave.salud_maxima]
	barra_salud.max_value = nave.salud_maxima
	barra_salud.value = nave.salud_actual
	salud.modulate = Color("ff8979") if nave.salud_actual <= nave.salud_maxima * 0.25 else Color.WHITE
	reparar.disabled = nave.salud_actual >= nave.salud_maxima
	var capacidad: float = maxf(nave.capacidad_combustible, 0)
	var actual: float = nave.combustible_actual
	var reserva: float = nave.combustible_reserva
	combustible.text = "Tanque: %.1f / %.1f L\nReserva a bordo: %.1f L" % [actual, capacidad, reserva]
	barra.max_value = maxf(capacidad, 1)
	barra.value = actual
	cantidad.max_value = maxf(0, minf(reserva, capacidad - actual))
	cargar.disabled = cantidad.max_value <= 0
	if cantidad.value <= 0 and cantidad.max_value > 0:
		cantidad.value = cantidad.max_value
	var elegido: Node3D = planetas[destinos.selected] if destinos.selected >= 0 and destinos.selected < planetas.size() else null
	mapa.destino = elegido
	var equipo := _equipo_seleccionado()
	var herramientas_kg := _peso_seleccionado()
	var total: float = nave.calcular_peso(herramientas_kg)
	var exceso: float = maxf(total - nave.peso_limite, 0)
	peso.text = "%.1f / %.1f kg\nNave: %.1f · Equipo y objetos: %.1f\nCombustible + reserva: %.1f kg" % [
		total, nave.peso_limite, nave.peso_vacio, herramientas_kg,
		nave.calcular_peso(0) - nave.peso_vacio
	]
	if exceso > 0:
		peso.text += "\nEXCESO DE PESO: +%.1f kg" % exceso
	peso.modulate = Color("ffb85c") if exceso > 0 else Color.WHITE
	barra_peso.max_value = maxf(nave.peso_limite, 1)
	barra_peso.value = total
	barra_peso.modulate = Color("ffb85c") if exceso > 0 else Color.WHITE
	confirmar.disabled = exceso > 0 or elegido == null or sistema_misiones == null
	resumen.text = "Destino: %s  |  Objetivo: %s\nHerramientas: %s" % [
		str(elegido.name) if elegido != null else "Sin planetas disponibles",
		objetivos.get_item_text(objetivos.selected),
		", ".join(equipo) if not equipo.is_empty() else "Ninguna seleccionada"
	]


func _equipo_seleccionado() -> Array[String]:
	var equipo: Array[String] = []
	for i in seleccion.size():
		if seleccion[i].button_pressed:
			equipo.append(herramientas[i])
	return equipo


func _reparar_nave() -> void:
	if nave == null:
		return
	var reparado: float = nave.reparar_nave()
	_actualizar()
	estado.text = "Casco reparado: +%.1f puntos de salud." % reparado
	estado.show()


func _cargar_combustible() -> void:
	var transferido: float = nave.cargar_combustible(cantidad.value)
	_actualizar()
	estado.text = "Se cargaron %.1f L al tanque." % transferido
	estado.show()


func _guardar_plan() -> void:
	estado.show()
	if destinos.selected < 0 or destinos.selected >= planetas.size():
		estado.text = "Selecciona un destino disponible."
		return
	var total: float = nave.calcular_peso(_peso_seleccionado())
	if total > nave.peso_limite:
		estado.text = "Reduce el peso antes de crear la expedicion."
		return
	if sistema_misiones == null:
		estado.text = "No se encontro el menu de misiones."
		return
	var distribucion: Dictionary = {}
	if inventario != null:
		distribucion = inventario.objetos.preparar_equipo(_objetos_equipo())
		if distribucion.is_empty():
			estado.text = "Libera slots en la mochila antes de crear la expedicion."
			return
	var plan := {
		"destino": str(planetas[destinos.selected].get_path()),
		"objetivo": objetivos.get_item_text(objetivos.selected),
		"objetivo_indice": objetivos.selected,
		"herramientas": _equipo_seleccionado(),
		"peso_kg": total,
		"peso_carga_kg": _peso_seleccionado()
	}
	var id: String = sistema_misiones.crear_expedicion(plan, str(planetas[destinos.selected].name))
	if id.is_empty():
		estado.text = "No se pudo registrar la expedicion."
		return
	plan["mision_id"] = id
	nave.plan_mision = plan
	if inventario != null:
		inventario.objetos.aplicar(distribucion)
	estado.text = "Expedicion registrada en el menu de misiones."


func _peso_herramienta(indice: int) -> float:
	return maxf(pesos_herramientas[indice], 0) if indice < pesos_herramientas.size() else 0.0


func _peso_seleccionado() -> float:
	var total := 0.0
	var ids: Array[String] = []
	for i in seleccion.size():
		if seleccion[i].button_pressed:
			total += _peso_herramienta(i)
			ids.append(_id_herramienta(i))
	if inventario != null:
		total += inventario.objetos.peso_restante(ids)
	return total


func _id_herramienta(indice: int) -> String:
	return "herramienta:" + herramientas[indice].to_snake_case()


func _objetos_equipo() -> Array[Dictionary]:
	var equipo: Array[Dictionary] = []
	for i in seleccion.size():
		if seleccion[i].button_pressed:
			equipo.append({"id": _id_herramienta(i), "nombre": herramientas[i], "cantidad": 1,
				"icono": imagenes_herramientas[i] if i < imagenes_herramientas.size() else null,
				"peso": _peso_herramienta(i), "tipo": "herramienta", "max_apilado": 1})
	return equipo


func _texto(padre: Node, texto: String, tamano: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_font_size_override("font_size", tamano)
	padre.add_child(etiqueta)
	return etiqueta


func _boton(padre: Node, texto: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size.y = 40
	padre.add_child(boton)
	return boton


func _panel(padre: Node, titulo: String, ancho: float, expandir: bool = false) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = ancho
	if expandir:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padre.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	panel.add_child(columna)
	if not titulo.is_empty():
		_texto(columna, titulo, 18)
		var linea := HSeparator.new()
		columna.add_child(linea)
	return columna


func _imagen(padre: Node, textura: Texture2D, descripcion: String, alto: float, ancho: float = 0) -> void:
	var espacio := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.06, 0.09, 0.8)
	estilo.border_color = Color("28616c")
	estilo.set_border_width_all(1)
	estilo.set_content_margin_all(4)
	espacio.add_theme_stylebox_override("panel", estilo)
	espacio.custom_minimum_size = Vector2(ancho, alto)
	padre.add_child(espacio)
	var imagen := TextureRect.new()
	imagen.texture = textura
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	espacio.add_child(imagen)
	if textura == null:
		var etiqueta := Label.new()
		etiqueta.text = descripcion
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiqueta.modulate = Color("688494")
		etiqueta.add_theme_font_size_override("font_size", 13)
		espacio.add_child(etiqueta)


func _crear_tema() -> void:
	theme = Theme.new()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", Color("d6edf0"))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.025, 0.08, 0.12, 0.95)
	panel.border_color = Color("28616c")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	panel.content_margin_left = 14
	panel.content_margin_right = 14
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	theme.set_stylebox("panel", "PanelContainer", panel)
	var boton := panel.duplicate() as StyleBoxFlat
	boton.bg_color = Color("10434e")
	boton.border_color = Color("39dbe1")
	theme.set_stylebox("normal", "Button", boton)
	var hover := boton.duplicate() as StyleBoxFlat
	hover.bg_color = Color("176172")
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	for tipo in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(tipo, "CheckBox", StyleBoxEmpty.new())
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color("24cbd7")
	relleno.set_corner_radius_all(3)
	theme.set_stylebox("fill", "ProgressBar", relleno)
