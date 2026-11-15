extends Node3D

@export var intensidad_navegacion: float = 3.0
@export var intensidad_focos: float = 3.0

var baliza: Node3D
var tiempo := 0.0
var malla: MeshInstance3D


func _ready() -> void:
	malla = get_parent().get_node("Starship")
	_crear_indicador("BaborRojo", Color(1, 0.04, 0.02), _extremo(0, 1) + Vector3(0.12, 0, 0))
	_crear_indicador("EstriborVerde", Color(0.03, 1, 0.2), _extremo(0, -1) - Vector3(0.12, 0, 0))
	baliza = _crear_indicador("BalizaBlanca", Color(0.85, 0.94, 1), _extremo(1, 1) + Vector3(0, 0.12, 0))
	var proa := _extremo(2, 1) + Vector3(0, 0, 0.2)
	for lado in [-1, 1]:
		var posicion_foco := proa + Vector3(lado * 0.6, 0, 0)
		_crear_indicador("Faro%d" % lado, Color(0.7, 0.85, 1), posicion_foco)
		var foco := SpotLight3D.new()
		foco.name = "FocoProa%d" % lado
		foco.position = posicion_foco
		foco.rotation.y = PI
		foco.light_color = Color(0.8, 0.9, 1)
		foco.light_energy = intensidad_focos
		foco.spot_range = 120.0
		foco.spot_angle = 32.0
		foco.shadow_enabled = true
		add_child(foco)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	tiempo += delta
	# Un destello lento cada dos segundos.
	baliza.visible = fmod(tiempo, 2.0) < 0.16


func _crear_indicador(nombre: String, color: Color, posicion_luz: Vector3) -> Node3D:
	var soporte := Node3D.new()
	soporte.name = nombre
	soporte.position = posicion_luz
	add_child(soporte)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = intensidad_navegacion
	var esfera := SphereMesh.new()
	esfera.radius = 0.12
	esfera.height = 0.24
	esfera.radial_segments = 12
	esfera.rings = 6
	esfera.material = material
	var indicador := MeshInstance3D.new()
	indicador.mesh = esfera
	indicador.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	soporte.add_child(indicador)
	var luz := OmniLight3D.new()
	luz.light_color = color
	luz.light_energy = 0.3
	luz.omni_range = 8.0
	soporte.add_child(luz)
	return soporte


func _extremo(eje: int, signo: int) -> Vector3:
	var caja := malla.get_aabb()
	var limite: float = caja.end[eje] if signo > 0 else caja.position[eje]
	var margen: float = caja.size[eje] * 0.015
	var acumulado := Vector3.ZERO
	var cantidad := 0
	var vertices: PackedVector3Array = malla.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for vertice in vertices:
		if absf(vertice[eje] - limite) <= margen:
			acumulado += vertice
			cantidad += 1
	var punto := acumulado / maxf(cantidad, 1)
	return to_local(malla.to_global(punto))
