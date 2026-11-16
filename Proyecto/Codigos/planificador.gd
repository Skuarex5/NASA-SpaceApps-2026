extends Control

signal cerrar_solicitado

const MAPA = preload("res://Proyecto/Codigos/mapa_orbital.gd")
const IDS_HERRAMIENTAS: Array[String] = [
	"herramienta:camara", "herramienta:radar", "herramienta:kit_de_reparacion", "herramienta:oxigeno",
	"herramienta:provisiones", "herramienta:escaner_mineral", "herramienta:taladro", "herramienta:baliza_de_senal"
]

@export_group("Imagenes opcionales")
@export var imagen_fondo: Texture2D
@export var imagen_configuracion: Texture2D
@export var imagen_recursos: Texture2D
@export var imagen_combustible: Texture2D
@export var imagen_herramientas: Texture2D
@export_group("Herramientas disponibles")
@export var herramientas: Array[String] = [
	"Camera", "Radar", "Repair kit", "Oxygen", "Supplies",
	"Mineral scanner", "Drill", "Signal beacon"
]
@export var imagenes_herramientas: Array[Texture2D] = []
@export var pesos_herramientas: Array[float] = [10.0, 25.0, 15.0, 12.0, 8.0, 6.0, 18.0, 4.0]

var nave: RigidBody3D
var planetas: Array[Node3D] = []
var mapa: Control
var destinos: OptionButton
var clima_destino: Label
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
var rocky: CharacterBody3D
var llevar_rocky: CheckBox
var distancia_rocky: SpinBox


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
	_texto(estructura, "MISSION PLANNER", 28)
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
	_crear_configuracion(_panel(columnas, "CONFIGURATION", 240))
	_crear_mapa(_panel(columnas, "ORBITAL MAP", 420, true))
	_crear_recursos(_panel(columnas, "RESOURCES & CARGO", 280))
	var pie := _panel(contenido, "", 0)
	resumen = _texto(pie, "", 17)
	estado = _texto(pie, "", 15)
	estado.hide()
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 16)
	pie.add_child(botones)
	confirmar = _boton(botones, "Create expedition")
	confirmar.pressed.connect(_guardar_plan)
	volver = _boton(botones, "Return to game (Esc)")
	volver.pressed.connect(func(): cerrar_solicitado.emit())
	hide()


func configurar(vehiculo: RigidBody3D, sistema: Node3D, misiones: Node, gestor_inventario: Node = null, companero: CharacterBody3D = null) -> void:
	nave = vehiculo
	sistema_misiones = misiones
	inventario = gestor_inventario
	rocky = companero
	planetas.clear()
	if sistema != null:
		for hijo in sistema.get_children():
			if hijo is Node3D:
				planetas.append(hijo)
	destinos.clear()
	for planeta in planetas:
		destinos.add_item(str(planeta.get_meta("display_name", planeta.name)))
	mapa.nave = nave
	mapa.planetas = planetas
	var plan: Dictionary = nave.plan_mision
	llevar_rocky.disabled = rocky == null
	distancia_rocky.editable = rocky != null
	llevar_rocky.set_pressed_no_signal(rocky.llevar_a_expedicion if rocky != null else false)
	distancia_rocky.set_value_no_signal(rocky.distancia_seguimiento if rocky != null else 1.5)
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
	_imagen(columna, imagen_configuracion, "Configuration image", 32)
	_texto(columna, "ORIGIN", 14)
	_texto(columna, "Current ship position", 16)
	_texto(columna, "DESTINATION", 14)
	destinos = OptionButton.new()
	columna.add_child(destinos)
	destinos.item_selected.connect(func(_i): _actualizar())
	clima_destino = _texto(columna, "", 13)
	clima_destino.modulate = Color("9dbec9")
	_texto(columna, "OBJECTIVE", 14)
	objetivos = OptionButton.new()
	for objetivo in ["Reconnaissance", "Exploration", "Transport"]:
		objetivos.add_item(objetivo)
	columna.add_child(objetivos)
	objetivos.item_selected.connect(func(_i): _actualizar())
	_texto(columna, "EXPEDITION COMPANION", 14)
	llevar_rocky = CheckBox.new()
	llevar_rocky.text = "Bring Rocky"
	llevar_rocky.tooltip_text = "If unchecked, Rocky waits inside the ship while you explore the planet. Saved when you create the expedition."
	columna.add_child(llevar_rocky)
	llevar_rocky.toggled.connect(func(_valor): _actualizar())
	_texto(columna, "Following distance", 14)
	distancia_rocky = SpinBox.new()
	distancia_rocky.min_value = 0.8
	distancia_rocky.max_value = 4.0
	distancia_rocky.step = 0.1
	distancia_rocky.suffix = "m"
	distancia_rocky.value = 1.5
	columna.add_child(distancia_rocky)
	distancia_rocky.value_changed.connect(func(_valor): _actualizar())
	_texto(columna, "EXPEDITION EQUIPMENT", 14)
	_imagen(columna, imagen_herramientas, "Equipment image", 32)
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
	_texto(columna, "Drag: pan  |  Scroll wheel: zoom", 14)
	mapa.tooltip_text = "The dashed line marks the destination; it is not a calculated orbital trajectory."
	var centrar := _boton(columna, "Frame ship and planets")
	centrar.pressed.connect(func(): mapa.reencuadrar())


func _crear_recursos(columna: VBoxContainer) -> void:
	_imagen(columna, imagen_recursos, "Ship / resources image", 48)
	_texto(columna, "HULL HEALTH", 18)
	salud = _texto(columna, "", 16)
	barra_salud = ProgressBar.new()
	barra_salud.custom_minimum_size.y = 20
	columna.add_child(barra_salud)
	reparar = _boton(columna, "Repair ship")
	reparar.tooltip_text = "Onboard maintenance: fully restores hull health without consuming items."
	reparar.pressed.connect(_reparar_nave)
	_texto(columna, "FUEL", 18)
	_imagen(columna, imagen_combustible, "Fuel image", 40)
	combustible = _texto(columna, "", 16)
	barra = ProgressBar.new()
	barra.custom_minimum_size.y = 22
	columna.add_child(barra)
	_texto(columna, "LOAD FROM RESERVE (L)", 14)
	cantidad = SpinBox.new()
	cantidad.min_value = 0
	cantidad.step = 1
	cantidad.allow_greater = false
	columna.add_child(cantidad)
	cargar = _boton(columna, "Load fuel")
	cargar.pressed.connect(_cargar_combustible)
	cargar.tooltip_text = "Transfers fuel from the onboard reserve without exceeding tank capacity."
	_texto(columna, "TOTAL WEIGHT / LIMIT", 18)
	peso = _texto(columna, "", 15)
	barra_peso = ProgressBar.new()
	barra_peso.custom_minimum_size.y = 20
	columna.add_child(barra_peso)


func _actualizar() -> void:
	if nave == null:
		return
	salud.text = "%.1f / %.1f points" % [nave.salud_actual, nave.salud_maxima]
	barra_salud.max_value = nave.salud_maxima
	barra_salud.value = nave.salud_actual
	salud.modulate = Color("ff8979") if nave.salud_actual <= nave.salud_maxima * 0.25 else Color.WHITE
	reparar.disabled = nave.salud_actual >= nave.salud_maxima
	var capacidad: float = maxf(nave.capacidad_combustible, 0)
	var actual: float = nave.combustible_actual
	var reserva: float = nave.combustible_reserva
	combustible.text = "Tank: %.1f / %.1f L\nOnboard reserve: %.1f L" % [actual, capacidad, reserva]
	barra.max_value = maxf(capacidad, 1)
	barra.value = actual
	cantidad.max_value = maxf(0, minf(reserva, capacidad - actual))
	cargar.disabled = cantidad.max_value <= 0
	if cantidad.value <= 0 and cantidad.max_value > 0:
		cantidad.value = cantidad.max_value
	var elegido: Node3D = planetas[destinos.selected] if destinos.selected >= 0 and destinos.selected < planetas.size() else null
	mapa.destino = elegido
	if elegido:
		var perfil := preload("res://Proyecto/Codigos/Planetas/perfiles_planeta.gd").obtener(int(elegido.get_meta("bioma_superficie", 0)))
		clima_destino.text = "Weather: %s · Gravity: %.1f m/s²" % [perfil.clima, perfil.gravedad]
	var equipo := _equipo_seleccionado()
	var herramientas_kg := _peso_seleccionado()
	var total: float = nave.calcular_peso(herramientas_kg)
	var exceso: float = maxf(total - nave.peso_limite, 0)
	peso.text = "%.1f / %.1f kg\nShip: %.1f · Equipment and items: %.1f\nFuel + reserve: %.1f kg" % [
		total, nave.peso_limite, nave.peso_vacio, herramientas_kg,
		nave.calcular_peso(0) - nave.peso_vacio
	]
	if exceso > 0:
		peso.text += "\nOVERWEIGHT: +%.1f kg" % exceso
	peso.modulate = Color("ffb85c") if exceso > 0 else Color.WHITE
	barra_peso.max_value = maxf(nave.peso_limite, 1)
	barra_peso.value = total
	barra_peso.modulate = Color("ffb85c") if exceso > 0 else Color.WHITE
	confirmar.disabled = exceso > 0 or elegido == null or sistema_misiones == null
	resumen.text = "Destination: %s  |  Objective: %s\nEquipment: %s" % [
		str(elegido.get_meta("display_name", elegido.name)) if elegido != null else "No planets available",
		objetivos.get_item_text(objetivos.selected),
		", ".join(equipo) if not equipo.is_empty() else "None selected"
	]
	if rocky != null:
		resumen.text += "\nRocky: %s | Following distance: %.1f m" % [
			"joining you" if llevar_rocky.button_pressed else "staying in the ship", distancia_rocky.value
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
	estado.text = "Hull repaired: +%.1f health points." % reparado
	estado.show()


func _cargar_combustible() -> void:
	var transferido: float = nave.cargar_combustible(cantidad.value)
	_actualizar()
	estado.text = "Loaded %.1f L into the tank." % transferido
	estado.show()


func _guardar_plan() -> void:
	estado.show()
	if destinos.selected < 0 or destinos.selected >= planetas.size():
		estado.text = "Select an available destination."
		return
	var total: float = nave.calcular_peso(_peso_seleccionado())
	if total > nave.peso_limite:
		estado.text = "Reduce the weight before creating the expedition."
		return
	if sistema_misiones == null:
		estado.text = "Mission menu not found."
		return
	var distribucion: Dictionary = {}
	if inventario != null:
		distribucion = inventario.objetos.preparar_equipo(_objetos_equipo())
		if distribucion.is_empty():
			estado.text = "Free up backpack slots before creating the expedition."
			return
	var plan := {
		"destino": str(planetas[destinos.selected].get_path()),
		"objetivo": objetivos.get_item_text(objetivos.selected),
		"objetivo_indice": objetivos.selected,
		"herramientas": _equipo_seleccionado(),
		"peso_kg": total,
		"peso_carga_kg": _peso_seleccionado(),
		"llevar_rocky": llevar_rocky.button_pressed,
		"distancia_rocky": distancia_rocky.value
	}
	var destino_elegido := planetas[destinos.selected]
	var id: String = sistema_misiones.crear_expedicion(plan, str(destino_elegido.get_meta("display_name", destino_elegido.name)))
	if id.is_empty():
		estado.text = "Could not register the expedition."
		return
	plan["mision_id"] = id
	nave.plan_mision = plan
	if rocky != null:
		rocky.configurar_expedicion(plan.llevar_rocky, plan.distancia_rocky)
	if inventario != null:
		inventario.objetos.aplicar(distribucion)
	estado.text = "Expedition added to the mission menu."


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
	if indice < IDS_HERRAMIENTAS.size():
		return IDS_HERRAMIENTAS[indice]
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
