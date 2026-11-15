extends CharacterBody3D

@export var jugador: CharacterBody3D
@export var mascota: Node3D

@export_group("Seguimiento")
@export_range(0.5, 4.0, 0.1) var distancia_seguimiento: float = 1.1
@export_range(0.1, 1.0, 0.05) var margen_parada: float = 0.25
@export_range(0.5, 8.0, 0.1) var velocidad_seguimiento: float = 3.5
@export_range(1.0, 20.0, 0.5) var aceleracion: float = 10.0
@export_range(1.0, 15.0, 0.5) var gravedad: float = 9.8
@export_range(0.5, 20.0, 0.5) var suavidad_giro: float = 8.0

@export_group("Paso simulado")
@export_range(0.0, 0.1, 0.005) var balanceo_paso: float = 0.025
@export_range(1.0, 16.0, 0.5) var frecuencia_paso: float = 8.0

var fase_paso: float = 0.0
var diferencia_giro_visual: float = 0.0
var rotacion_visual_base: Vector3


func _ready() -> void:
	if not is_instance_valid(jugador) or not is_instance_valid(mascota):
		push_error("RockyFollower necesita referencias al jugador y a Rocky.")
		set_physics_process(false)
		return

	global_position = mascota.global_position
	rotacion_visual_base = mascota.global_rotation
	diferencia_giro_visual = wrapf(
		rotacion_visual_base.y - global_rotation.y,
		-PI,
		PI
	)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(jugador) or not is_instance_valid(mascota):
		return

	var direccion_atras := Vector3.BACK
	var modelo_jugador := jugador.get_node_or_null("Model") as Node3D
	if modelo_jugador != null:
		direccion_atras = modelo_jugador.global_basis.z
		direccion_atras.y = 0.0
		if direccion_atras.length_squared() > 0.001:
			direccion_atras = direccion_atras.normalized()
		else:
			direccion_atras = Vector3.BACK

	var destino := jugador.global_position + direccion_atras * distancia_seguimiento
	var direccion := destino - global_position
	direccion.y = 0.0
	var distancia := direccion.length()

	var velocidad_objetivo := Vector3.ZERO
	if distancia > margen_parada:
		velocidad_objetivo = direccion.normalized() * velocidad_seguimiento

	velocity.x = move_toward(velocity.x, velocidad_objetivo.x, aceleracion * delta)
	velocity.z = move_toward(velocity.z, velocidad_objetivo.z, aceleracion * delta)

	if not is_on_floor():
		velocity.y -= gravedad * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	move_and_slide()
	_actualizar_orientacion_y_paso(delta)


func _actualizar_orientacion_y_paso(delta: float) -> void:
	var rapidez := Vector2(velocity.x, velocity.z).length()
	if rapidez > 0.1:
		var direccion_movimiento := Vector3(velocity.x, 0.0, velocity.z).normalized()
		var angulo_objetivo := atan2(direccion_movimiento.x, direccion_movimiento.z)
		var suavizado := 1.0 - exp(-suavidad_giro * delta)
		var rotacion := global_rotation
		rotacion.y = lerp_angle(rotacion.y, angulo_objetivo, suavizado)
		global_rotation = rotacion
		fase_paso += delta * frecuencia_paso
	else:
		fase_paso = 0.0

	var balanceo := 0.0
	if rapidez > 0.1:
		balanceo = absf(sin(fase_paso)) * balanceo_paso

	mascota.global_position = global_position + Vector3.UP * balanceo
	var rotacion_visual := rotacion_visual_base
	rotacion_visual.y = global_rotation.y + diferencia_giro_visual
	mascota.global_rotation = rotacion_visual
