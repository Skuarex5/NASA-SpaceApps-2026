@tool
extends Node

@export var decoracion: Node3D


func _ready() -> void:
	call_deferred("_preparar")


func _preparar() -> void:
	if not is_instance_valid(decoracion):
		return
	_luz("LamparaEscritorio", Vector3(0.5, 0.82, 0.5), Color(0.83, 0.91, 1.0), 1.6, 1.8, true)
	_luz("ComputadoraRetro", Vector3(0.45, 0.70, 0.5), Color(0.25, 0.75, 0.85), 0.16, 0.85)
	_luz("Generador", Vector3(0.5, 0.58, 0.96), Color(1.0, 0.32, 0.10), 0.22, 0.8)


func _luz(nombre: String, punto: Vector3, color: Color, energia: float, alcance: float, dirigida := false) -> void:
	var objeto := decoracion.get_node_or_null(nombre) as Node3D
	if not objeto or objeto.has_node("LuzObjeto"):
		return
	var caja: AABB
	var primero := true
	for malla in objeto.find_children("*", "MeshInstance3D", true, false):
		if not malla.mesh or not malla.is_visible_in_tree():
			continue
		var actual: AABB = malla.global_transform * malla.get_aabb()
		caja = actual if primero else caja.merge(actual)
		primero = false
	if primero:
		return
	var luz: Light3D
	if dirigida:
		var foco := SpotLight3D.new()
		foco.spot_range = alcance
		foco.spot_angle = 58.0
		foco.spot_attenuation = 1.4
		foco.shadow_enabled = true
		luz = foco
	else:
		var brillo := OmniLight3D.new()
		brillo.omni_range = alcance
		brillo.omni_attenuation = 2.0
		luz = brillo
	luz.name = "LuzObjeto"
	luz.light_color = color
	luz.light_energy = energia
	luz.light_size = 0.04
	luz.distance_fade_enabled = true
	luz.distance_fade_begin = 12.0
	luz.distance_fade_length = 4.0
	objeto.add_child(luz)
	# Compensar la escala de importacion: alcance y posicion en metros de juego.
	luz.global_transform = Transform3D(Basis.IDENTITY, caja.position + caja.size * punto)
	if dirigida:
		luz.global_rotation.x = -PI / 2.0
