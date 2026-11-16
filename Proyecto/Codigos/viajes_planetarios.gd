extends CanvasLayer

enum Estado { ESPACIO, CARGANDO, SUPERFICIE }

@export var nave: RigidBody3D
@export var astronauta: CharacterBody3D
@export var planetas: Node3D
@export var rocky: CharacterBody3D
@export_range(2.0, 10.0, 0.1) var distancia_despegue: float = 3.0
@export_range(1.0, 6.0, 0.25) var escala_nave_aterrizada: float = 3.0

var estado := Estado.ESPACIO
var destinos: Array[Dictionary] = []
var planeta_actual: Dictionary = {}
var superficie_actual: Node3D
var superficies: Dictionary = {}
var posicion_anterior: Vector3
var transform_vuelo: Transform3D
var transform_interior: Transform3D
var gravedad_original: Dictionary = {}
var entorno_original: Environment
var rotacion_camara_original: Vector3
var rotacion_modelo_original: Vector3
var visibilidad_espacio: Dictionary = {}
var espera_reentrada := 0.0
var carga: ColorRect
var texto_carga: Label
var aviso_despegue: CenterContainer
var titulo_planeta: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 170
	_crear_interfaz()
	for planeta in planetas.get_children():
		if not planeta is Node3D:
			continue
		var caja := AABB()
		var primera := true
		for malla in planeta.find_children("*", "MeshInstance3D", true, false):
			var actual: AABB = malla.global_transform * malla.get_aabb()
			caja = actual if primera else caja.merge(actual)
			primera = false
		if primera:
			continue
		var radio := caja.size[caja.get_longest_axis_index()] * 0.5
		destinos.append({"nodo": planeta, "nombre": str(planeta.get_meta("display_name", planeta.name)), "centro": caja.get_center(),
			"radio": radio, "entrada": radio + maxf(20, radio * 0.06), "indice": destinos.size()})
	posicion_anterior = nave.global_position


func _crear_interfaz() -> void:
	titulo_planeta = Label.new()
	titulo_planeta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_planeta.add_theme_font_size_override("font_size", 22)
	titulo_planeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(titulo_planeta)
	titulo_planeta.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	titulo_planeta.offset_top = 20
	titulo_planeta.hide()
	aviso_despegue = CenterContainer.new()
	aviso_despegue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(aviso_despegue)
	aviso_despegue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	aviso_despegue.offset_top = -90
	aviso_despegue.offset_bottom = -50
	var opcion_despegue := HBoxContainer.new()
	opcion_despegue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opcion_despegue.add_theme_constant_override("separation", 4)
	aviso_despegue.add_child(opcion_despegue)
	var tecla_despegue := TextureRect.new()
	tecla_despegue.texture = preload("res://Proyecto/Texturas/InteraccionEscritorio/Q.png")
	tecla_despegue.custom_minimum_size = Vector2(40, 40)
	tecla_despegue.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tecla_despegue.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tecla_despegue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opcion_despegue.add_child(tecla_despegue)
	var texto_despegue := Label.new()
	texto_despegue.text = "Take off and return to space"
	texto_despegue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto_despegue.add_theme_font_size_override("font_size", 16)
	texto_despegue.add_theme_color_override("font_shadow_color", Color.BLACK)
	texto_despegue.add_theme_constant_override("shadow_offset_x", 2)
	texto_despegue.add_theme_constant_override("shadow_offset_y", 2)
	texto_despegue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opcion_despegue.add_child(texto_despegue)
	aviso_despegue.hide()
	carga = ColorRect.new()
	carga.color = Color("050b14")
	add_child(carga)
	carga.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	carga.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 24)
	centro.add_child(contenido)
	texto_carga = Label.new()
	texto_carga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_carga.add_theme_font_size_override("font_size", 24)
	contenido.add_child(texto_carga)
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(380, 12)
	barra.indeterminate = true
	barra.show_percentage = false
	contenido.add_child(barra)
	carga.hide()


func _physics_process(delta: float) -> void:
	aviso_despegue.visible = estado == Estado.SUPERFICIE and not get_tree().paused and _cerca_de_nave()
	if get_tree().paused or estado == Estado.CARGANDO:
		return
	if estado == Estado.SUPERFICIE:
		if astronauta.global_position.y < superficie_actual.global_position.y - 30:
			astronauta.global_position = superficie_actual.to_global(superficie_actual.punto_astronauta)
			astronauta.velocity = Vector3.ZERO
		return
	espera_reentrada = maxf(espera_reentrada - delta, 0)
	var actual := nave.global_position
	if nave.pilotando and espera_reentrada <= 0:
		for destino in destinos:
			var punto := Geometry3D.get_closest_point_to_segment(destino.centro, posicion_anterior, actual)
			if punto.distance_to(destino.centro) <= float(destino.entrada):
				estado = Estado.CARGANDO
				_aterrizar.call_deferred(destino)
				return
	posicion_anterior = actual


func _input(event: InputEvent) -> void:
	if estado == Estado.CARGANDO:
		get_viewport().set_input_as_handled()
		return
	if estado == Estado.SUPERFICIE and not get_tree().paused and _cerca_de_nave():
		if event.is_action_pressed("navegar") and not event.is_echo():
			estado = Estado.CARGANDO
			_despegar.call_deferred()
			get_viewport().set_input_as_handled()


func _cerca_de_nave() -> bool:
	# Medir desde el casco para que Q siga siendo accesible con la nave ampliada.
	var colision := nave.get_node("CollisionShape3D") as CollisionShape3D
	var mitad := (colision.shape as BoxShape3D).size * 0.5
	var local := colision.to_local(astronauta.global_position)
	var cercano := colision.to_global(local.clamp(-mitad, mitad))
	return astronauta.global_position.distance_to(cercano) <= distancia_despegue


func _mostrar_carga(texto: String) -> void:
	texto_carga.text = texto
	carga.modulate.a = 1
	carga.show()
	aviso_despegue.hide()
	get_tree().paused = true
	astronauta.girando_camara = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _aterrizar(destino: Dictionary) -> void:
	_mostrar_carga("Entering %s…" % destino.nombre)
	await get_tree().process_frame
	await get_tree().process_frame
	planeta_actual = destino
	transform_vuelo = nave.global_transform
	var salida: Vector3 = (posicion_anterior - Vector3(destino.centro)).normalized()
	if salida.length_squared() < 0.1:
		salida = Vector3.BACK
	transform_vuelo.origin = destino.centro + salida * (float(destino.entrada) + 120.0)
	var horizontal := Vector3(salida.x, 0, salida.z).normalized()
	if horizontal.length_squared() > 0.1:
		transform_vuelo.basis = Basis.looking_at(horizontal).scaled(nave.global_basis.get_scale())
	transform_interior = nave.posicion_guardada
	entorno_original = nave.camara_astronauta.environment
	rotacion_camara_original = astronauta.camera_pivot.rotation
	rotacion_modelo_original = astronauta.modelo.rotation
	gravedad_original.clear()
	for propiedad in ["gravedad_espacial", "gravedad_descenso", "velocidad_maxima_caida", "fuerza_salto"]:
		gravedad_original[propiedad] = astronauta.get(propiedad)
	visibilidad_espacio.clear()
	for nombre in ["Planetas", "SpaceshipInterior", "CampoAsteroides", "DirectionalLight3D"]:
		var nodo: Node3D = get_parent().get_node(nombre)
		visibilidad_espacio[nodo] = nodo.visible
		nodo.hide()
	nave.pilotando = false
	nave.freeze = true
	nave.linear_velocity = Vector3.ZERO
	nave.angular_velocity = Vector3.ZERO
	nave.tiempo_boost = 0
	nave._apagar_motores()
	nave.hud_controles.hide()
	nave.hud_boost.hide()
	nave.set_physics_process(false)
	nave.set_process_input(false)
	texto_carga.text = "Preparing the surface of %s…" % destino.nombre
	if not superficies.has(destino.indice):
		var superficie := preload("res://Proyecto/Codigos/superficie_planeta.gd").new()
		superficie.name = "Superficie_%s" % destino.nombre
		superficie.bioma = int(destino.nodo.get_meta("bioma_superficie", int(destino.indice) % 2))
		superficie.nombre_planeta = destino.nombre
		superficie.astronauta = astronauta
		superficie.position = Vector3(10000 + int(destino.indice) * 1500, -10000, 0)
		get_parent().add_child(superficie)
		superficies[destino.indice] = superficie
	superficie_actual = superficies[destino.indice]
	var punto_aterrizaje: Vector3 = superficie_actual.punto_nave * escala_nave_aterrizada
	nave.global_transform = Transform3D(Basis.IDENTITY.scaled(transform_vuelo.basis.get_scale() * escala_nave_aterrizada), superficie_actual.to_global(punto_aterrizaje))
	nave.collision_layer = nave.capa_nave
	nave.collision_mask = nave.mascara_nave
	nave.nave_visual.rotation = nave.rotacion_visual_inicial
	nave.show()
	superficie_actual.punto_astronauta = Vector3(1.8 * escala_nave_aterrizada, 0.08, -3.2 - (escala_nave_aterrizada - 1.0) * 0.4)
	astronauta.global_transform = Transform3D(Basis.IDENTITY, superficie_actual.to_global(superficie_actual.punto_astronauta))
	astronauta.velocity = Vector3.ZERO
	astronauta.preparando_salto = false
	astronauta.salto_en_aire = false
	astronauta.girando_camara = false
	astronauta.camera_pivot.rotation = Vector3.ZERO
	astronauta.modelo.rotation = Vector3.ZERO
	superficie_actual.establecer_activa(true)
	astronauta.gravedad_espacial = float(superficie_actual.perfil.gravedad)
	astronauta.gravedad_descenso = astronauta.gravedad_espacial
	astronauta.velocidad_maxima_caida = 12.0
	astronauta.fuerza_salto = clampf(sqrt(astronauta.gravedad_espacial * 2.6), 3.0, 5.2)
	astronauta.collision_layer = nave.capa_astronauta
	astronauta.collision_mask = nave.mascara_astronauta
	nave.personaje_visual.show()
	astronauta.set_physics_process(true)
	astronauta.set_process_input(true)
	astronauta.set_process_unhandled_input(true)
	nave.camara_astronauta.environment = superficie_actual.entorno
	nave.camara_astronauta.make_current()
	if is_instance_valid(rocky):
		rocky.preparar_superficie()
	titulo_planeta.text = "%s · %s" % [destino.nombre, superficie_actual.perfil.clima]
	titulo_planeta.show()
	await get_tree().process_frame
	await get_tree().process_frame
	nave.camara_astronauta._actualizar_colision()
	await _terminar_carga(Estado.SUPERFICIE)


func _despegar(emergencia: bool = false) -> void:
	_mostrar_carga("Emergency evacuation from %s…" % planeta_actual.nombre if emergencia else "Taking off from %s…" % planeta_actual.nombre)
	await get_tree().process_frame
	await get_tree().process_frame
	superficie_actual.establecer_activa(false)
	for nodo in visibilidad_espacio:
		nodo.visible = visibilidad_espacio[nodo]
	for propiedad in gravedad_original:
		astronauta.set(propiedad, gravedad_original[propiedad])
	astronauta.camera_pivot.rotation = rotacion_camara_original
	astronauta.modelo.rotation = rotacion_modelo_original
	nave.camara_astronauta.environment = entorno_original
	nave.global_transform = transform_vuelo
	nave.linear_velocity = Vector3.ZERO
	nave.angular_velocity = Vector3.ZERO
	nave.set_physics_process(true)
	nave.set_process_input(true)
	nave.entrar_nave()
	if is_instance_valid(rocky):
		rocky.volver_a_cabina()
	# Entrar a pilotar no debe sustituir la posicion guardada en la cabina.
	nave.posicion_guardada = transform_interior
	posicion_anterior = nave.global_position
	espera_reentrada = 2.0
	titulo_planeta.hide()
	await _terminar_carga(Estado.ESPACIO)


func _terminar_carga(siguiente: Estado) -> void:
	await get_tree().create_timer(0.25).timeout
	var fundido := create_tween()
	fundido.tween_property(carga, "modulate:a", 0.0, 0.2)
	await fundido.finished
	carga.hide()
	estado = siguiente
	get_tree().paused = false
