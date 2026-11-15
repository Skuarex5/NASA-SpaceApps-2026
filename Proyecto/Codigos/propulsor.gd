extends Node3D

var potencia_objetivo := 0.0
var potencia_actual := 0.0
var turbo_activo := false
var capas: Array[MeshInstance3D] = []
var iluminacion: OmniLight3D


func _ready() -> void:
	for halo in [false, true]:
		var capa := MeshInstance3D.new()
		capa.name = "Halo" if halo else "Nucleo"
		capa.mesh = _crear_pluma(1.05 if halo else 0.55, halo)
		capa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = preload("res://Proyecto/Efectos/FuegoMotor/engine_flame.gdshader")
		material.set_shader_parameter("envoltura", halo)
		capa.material_override = material
		add_child(capa)
		capas.append(capa)
	iluminacion = OmniLight3D.new()
	iluminacion.position.z = -0.35
	iluminacion.light_color = Color(0.3, 0.6, 1)
	iluminacion.omni_range = 8.0
	add_child(iluminacion)
	apagar()


func actualizar_intensidad(potencia: float, con_turbo: bool) -> void:
	potencia_objetivo = clampf(potencia, 0, 1)
	turbo_activo = con_turbo


func _process(delta: float) -> void:
	potencia_actual = move_toward(potencia_actual, potencia_objetivo, delta * 3.5)
	visible = potencia_actual > 0.01
	scale.z = lerpf(0.35, 1.0, potencia_actual) * (1.6 if turbo_activo else 1.0)
	for capa in capas:
		capa.material_override.set_shader_parameter("potencia", potencia_actual)
		capa.material_override.set_shader_parameter("turbo", 1.0 if turbo_activo else 0.0)
	iluminacion.light_energy = potencia_actual * (1.6 if turbo_activo else 0.8)


func apagar() -> void:
	potencia_objetivo = 0
	potencia_actual = 0
	turbo_activo = false
	if iluminacion != null:
		iluminacion.light_energy = 0
	hide()


func _crear_pluma(radio: float, halo: bool) -> ArrayMesh:
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	var anillos := 28
	var segmentos := 24
	for fila in anillos:
		for columna in segmentos:
			for esquina in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
				var u := float(columna + esquina.x) / segmentos
				var t := float(fila + esquina.y) / anillos
				var ancho := radio * (1.0 + t * 0.35) * (1.0 - pow(t, 1.5) * (0.7 if halo else 0.9))
				superficie.set_uv(Vector2(u, t))
				superficie.set_normal(Vector3(cos(u * TAU), sin(u * TAU), 0))
				superficie.add_vertex(Vector3(cos(u * TAU) * ancho, sin(u * TAU) * ancho, -t * 6.0))
	return superficie.commit()
