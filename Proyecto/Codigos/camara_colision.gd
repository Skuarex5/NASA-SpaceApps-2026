extends Camera3D

@export_range(0.01, 0.4, 0.01) var radio_seguridad: float = 0.14
@export_range(0.0, 1.5, 0.01) var altura_objetivo: float = 0.8
@export_range(0.0, 0.2, 0.01) var margen_pared: float = 0.04
@export_flags_3d_physics var mascara_paredes: int = 1

var posicion_original: Vector3
var cuerpo: CharacterBody3D
var consulta := PhysicsShapeQueryParameters3D.new()
var esfera := SphereShape3D.new()


func _ready() -> void:
	posicion_original = position
	cuerpo = get_parent().get_parent() as CharacterBody3D
	consulta.shape = esfera
	consulta.exclude = [cuerpo.get_rid()]
	process_priority = 100


func _process(_delta: float) -> void:
	if is_current():
		_actualizar_colision()


func _actualizar_colision() -> void:
	# Conservar la orbita original. Solo acercar la camara si encuentra una pared.
	var origen := cuerpo.global_position + Vector3.UP * altura_objetivo
	var deseada: Vector3 = get_parent().global_transform * posicion_original
	var recorrido := deseada - origen
	var longitud := recorrido.length()
	if longitud < 0.001:
		return
	esfera.radius = radio_seguridad
	consulta.transform = Transform3D(Basis.IDENTITY, origen)
	consulta.motion = recorrido
	consulta.collision_mask = mascara_paredes
	var resultado := get_world_3d().direct_space_state.cast_motion(consulta)
	var distancia := longitud
	if resultado[0] < 1.0:
		distancia = maxf(0.0, longitud * resultado[0] - margen_pared)
	global_position = origen + recorrido / longitud * distancia
