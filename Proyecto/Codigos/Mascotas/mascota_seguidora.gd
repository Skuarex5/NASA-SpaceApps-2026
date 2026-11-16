extends CharacterBody3D

@export var jugador: CharacterBody3D
@export var mascota: Node3D
@export var nave: RigidBody3D

@export_group("Seguimiento")
@export_range(0.8, 4.0, 0.1) var distancia_seguimiento: float = 1.5
@export_range(0.1, 1.0, 0.05) var margen_parada: float = 0.25
@export_range(0.5, 8.0, 0.1) var velocidad_seguimiento: float = 3.5
@export_range(1.0, 20.0, 0.5) var aceleracion: float = 6.0
@export_range(1.0, 20.0, 0.5) var desaceleracion: float = 9.0
@export_range(0.5, 20.0, 0.5) var suavidad_giro: float = 8.0

@export_group("Expedicion")
@export var llevar_a_expedicion: bool = true

@export_group("Paso simulado")
@export_range(0.0, 0.1, 0.005) var balanceo_paso: float = 0.025
@export_range(1.0, 16.0, 0.5) var frecuencia_paso: float = 8.0

var fase_paso := 0.0
var diferencia_giro_visual := 0.0
var rotacion_visual_base: Vector3
var capa_original: int
var mascara_original: int
var en_superficie := false
var siguiendo := false
var rastro: Array[Vector3] = []
var _transformacion_cabina: Transform3D
var _necesita_reubicacion := false
var _objetivo: Vector3
var _tiempo_objetivo := 0.0
var _balanceo_visual := 0.0


func _ready() -> void:
	if not is_instance_valid(jugador) or not is_instance_valid(mascota):
		push_error("Rocky necesita referencias al jugador y a su modelo.")
		set_physics_process(false)
		return
	capa_original = collision_layer
	mascara_original = collision_mask
	add_collision_exception_with(jugador)
	rotacion_visual_base = mascota.global_rotation
	diferencia_giro_visual = wrapf(rotacion_visual_base.y - global_rotation.y, -PI, PI)
	_transformacion_cabina = global_transform
	_reiniciar_rastro()


func configurar_expedicion(llevar: bool, distancia: float) -> void:
	llevar_a_expedicion = llevar
	distancia_seguimiento = clampf(distancia, 0.8, 4.0)
	siguiendo = false
	_reiniciar_rastro()


func preparar_superficie() -> void:
	if not en_superficie:
		_transformacion_cabina = global_transform
	en_superficie = true
	_necesita_reubicacion = llevar_a_expedicion
	_reiniciar_rastro()
	_desactivar()


func volver_a_cabina() -> void:
	en_superficie = false
	_necesita_reubicacion = false
	global_transform = _transformacion_cabina
	_reiniciar_rastro()
	_desactivar()


func _desactivar() -> void:
	hide()
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	siguiendo = false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(jugador) or not is_instance_valid(mascota):
		return
	if not jugador.is_physics_processing() or (is_instance_valid(nave) and nave.pilotando) or (en_superficie and not llevar_a_expedicion):
		_desactivar()
		return
	show()
	collision_layer = capa_original
	collision_mask = mascara_original
	# Reubicar solo al cambiar de zona o recuperarse de una caida, no al caminar.
	if _necesita_reubicacion or global_position.distance_to(jugador.global_position) > 100.0 or global_position.y < jugador.global_position.y - 25.0:
		_reubicar_cerca_del_jugador()
		_necesita_reubicacion = false
		_reiniciar_rastro()
	_actualizar_rastro()
	var distancia := _distancia_horizontal(global_position, jugador.global_position)
	if distancia <= distancia_seguimiento:
		siguiendo = false
	elif distancia > distancia_seguimiento + margen_parada:
		siguiendo = true
	_tiempo_objetivo -= delta
	if siguiendo and _tiempo_objetivo <= 0:
		_objetivo = _elegir_objetivo()
		_tiempo_objetivo = 0.15
	var velocidad_objetivo := Vector2.ZERO
	if siguiendo:
		var direccion := Vector2(_objetivo.x - global_position.x, _objetivo.z - global_position.z)
		var espacio_para_frenar := maxf(distancia - distancia_seguimiento, 0)
		var rapidez := minf(velocidad_seguimiento, sqrt(2.0 * desaceleracion * espacio_para_frenar))
		velocidad_objetivo = direccion.normalized() * rapidez
	var horizontal := Vector2(velocity.x, velocity.z)
	var respuesta := desaceleracion if velocidad_objetivo.length_squared() < horizontal.length_squared() else aceleracion
	horizontal = horizontal.move_toward(velocidad_objetivo, respuesta * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if not is_on_floor():
		velocity.y -= jugador.gravedad_espacial * delta
	elif velocity.y < 0:
		velocity.y = 0
	move_and_slide()
	_actualizar_orientacion_y_paso(delta)
	if not en_superficie:
		_transformacion_cabina = global_transform


func _distancia_horizontal(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _reiniciar_rastro() -> void:
	rastro.clear()
	if is_instance_valid(jugador):
		rastro.append(jugador.global_position)
		_objetivo = jugador.global_position
	_tiempo_objetivo = 0


func _actualizar_rastro() -> void:
	# Guardar el recorrido real permite seguir las esquinas por las que paso el jugador.
	if rastro.is_empty() or _distancia_horizontal(rastro.back(), jugador.global_position) >= 0.2:
		rastro.append(jugador.global_position)
	if rastro.size() > 256:
		rastro.pop_front()
	while rastro.size() > 1 and _distancia_horizontal(global_position, rastro[0]) < 0.3:
		rastro.pop_front()
		_tiempo_objetivo = 0


func _elegir_objetivo() -> Vector3:
	if _camino_libre(jugador.global_position):
		rastro.clear()
		rastro.append(jugador.global_position)
		return jugador.global_position
	# Saltar puntos solo cuando la esfera del cuerpo puede pasar sin atravesar muebles.
	var paso := maxi(1, ceili(float(rastro.size()) / 12.0))
	for indice in range(rastro.size() - 1, -1, -paso):
		if _camino_libre(rastro[indice]):
			var destino := rastro[indice]
			for i in indice:
				rastro.pop_front()
			return destino
	return rastro[0] if not rastro.is_empty() else jugador.global_position


func _camino_libre(punto_suelo: Vector3) -> bool:
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = $CollisionShape3D.shape
	consulta.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.08)
	consulta.motion = punto_suelo + Vector3.UP * 0.33 - consulta.transform.origin
	consulta.collision_mask = mascara_original
	consulta.exclude = [get_rid(), jugador.get_rid()]
	var resultado := get_world_3d().direct_space_state.cast_motion(consulta)
	return resultado.size() == 2 and resultado[0] > 0.98


func _reubicar_cerca_del_jugador() -> void:
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = $CollisionShape3D.shape
	consulta.collision_mask = mascara_original
	consulta.exclude = [get_rid(), jugador.get_rid()]
	var distancia := distancia_seguimiento
	for desplazamiento in [Vector3(distancia, 0.4, 0), Vector3(-distancia, 0.4, 0), Vector3(0, 0.4, distancia), Vector3(0, 0.4, -distancia)]:
		consulta.transform = Transform3D(Basis.IDENTITY, jugador.global_position + desplazamiento)
		if get_world_3d().direct_space_state.intersect_shape(consulta, 1).is_empty():
			global_position = consulta.transform.origin
			velocity = Vector3.ZERO
			return
	global_position = jugador.global_position + Vector3.UP * 0.6
	velocity = Vector3.ZERO


func _actualizar_orientacion_y_paso(delta: float) -> void:
	var rapidez := Vector2(velocity.x, velocity.z).length()
	if rapidez > 0.1:
		var direccion := Vector3(velocity.x, 0, velocity.z).normalized()
		var rotacion := global_rotation
		rotacion.y = lerp_angle(rotacion.y, atan2(direccion.x, direccion.z), 1.0 - exp(-suavidad_giro * delta))
		global_rotation = rotacion
		fase_paso += delta * frecuencia_paso * clampf(rapidez / 2.0, 0.3, 1.5)
	var balanceo := absf(sin(fase_paso)) * balanceo_paso * clampf(rapidez / 2.0, 0, 1)
	_balanceo_visual = lerpf(_balanceo_visual, balanceo, 1.0 - exp(-12.0 * delta))
	mascota.global_position = global_position + Vector3.UP * _balanceo_visual
	var rotacion_visual := rotacion_visual_base
	rotacion_visual.y = global_rotation.y + diferencia_giro_visual
	mascota.global_rotation = rotacion_visual