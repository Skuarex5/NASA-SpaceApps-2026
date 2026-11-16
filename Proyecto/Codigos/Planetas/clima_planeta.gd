extends Node3D

var astronauta: CharacterBody3D
var perfil: Dictionary
var emisores: Array[GPUParticles3D] = []
var activo := true
var azar := RandomNumberGenerator.new()
var espera_descarga := 6.0
var duracion_descarga := 0.0
var descarga: MeshInstance3D


func _ready() -> void:
	azar.seed = int(get_parent().ruido.seed) + 812
	var estilo: String = perfil.efecto
	match estilo:
		"rain": _emisor("Rain", 850, 1.4, Vector3(1.5, -22, 0.5), 14, Color(0.62, 0.78, 0.86, 0.48), Vector2(0.014, 0.38), false)
		"snow": _emisor("Snow", 420, 5.5, Vector3(3.5, -2.8, 0.7), 8, Color(0.88, 0.96, 1.0, 0.8), Vector2(0.065, 0.065))
		"sand": _emisor("WindblownSand", 480, 3.5, Vector3(8.0, -0.5, 1.3), 5, Color(0.70, 0.49, 0.26, 0.42), Vector2(0.055, 0.025))
		"ash":
			_emisor("Ash", 260, 5.0, Vector3(1.8, -1.3, 0.5), 8, Color(0.60, 0.56, 0.54, 0.65), Vector2(0.055, 0.055))
			_emisor("Embers", 70, 4.5, Vector3(1.2, 0.45, 0.3), 2, Color(1.0, 0.25, 0.035, 0.7), Vector2(0.035, 0.035), true, true)
		"radiation": _emisor("ChargedDust", 300, 5.5, Vector3(3.0, -0.3, 1.0), 5, Color(0.48, 0.85, 0.20, 0.5), Vector2(0.065, 0.065), true, true)
		"ion": _emisor("IonCrystals", 240, 4.5, Vector3(4.0, -0.7, -0.5), 7, Color(0.47, 0.61, 1.0, 0.65), Vector2(0.035, 0.12), true, true)
	if estilo in ["ion", "radiation"]:
		descarga = MeshInstance3D.new()
		descarga.name = "AtmosphericDischarge"
		descarga.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(descarga)
		descarga.hide()
	_actualizar_posicion()


func _emisor(nombre: String, cantidad: int, vida: float, viento: Vector3, altura: float, color: Color, tamano: Vector2, suave := true, luminoso := false) -> void:
	var emisor := GPUParticles3D.new()
	emisor.name = nombre
	emisor.amount = cantidad
	emisor.lifetime = vida
	emisor.preprocess = vida
	emisor.local_coords = false
	emisor.visibility_aabb = AABB(Vector3(-45, -35, -45), Vector3(90, 65, 90))
	emisor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emisor.set_meta("altura_emision", altura)
	var proceso := ParticleProcessMaterial.new()
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proceso.emission_box_extents = Vector3(18, 3 if suave else 0.5, 18)
	proceso.direction = viento.normalized()
	proceso.spread = 12.0 if suave else 3.0
	proceso.initial_velocity_min = viento.length() * 0.75
	proceso.initial_velocity_max = viento.length() * 1.15
	proceso.gravity = Vector3(0, -2.0 if not suave else -0.15, 0)
	proceso.scale_min = 0.55
	proceso.scale_max = 1.4
	var vida_color := Gradient.new()
	vida_color.offsets = PackedFloat32Array([0.0, 0.08, 0.8, 1.0])
	vida_color.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var rampa := GradientTexture1D.new()
	rampa.gradient = vida_color
	proceso.color_ramp = rampa
	emisor.process_material = proceso
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED if suave else BaseMaterial3D.BILLBOARD_FIXED_Y
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if luminoso:
		material.albedo_color = Color(color.r * 1.7, color.g * 1.7, color.b * 1.7, color.a)
	if suave:
		var degradado := Gradient.new()
		degradado.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
		var textura := GradientTexture2D.new()
		textura.width = 32
		textura.height = 32
		textura.gradient = degradado
		textura.fill = GradientTexture2D.FILL_RADIAL
		textura.fill_from = Vector2(0.5, 0.5)
		textura.fill_to = Vector2(1.0, 0.5)
		material.albedo_texture = textura
	var particula := QuadMesh.new()
	particula.size = tamano
	particula.material = material
	emisor.draw_pass_1 = particula
	add_child(emisor)
	emisores.append(emisor)


func _actualizar_posicion() -> void:
	if not is_instance_valid(astronauta):
		return
	for emisor in emisores:
		emisor.global_position = astronauta.global_position + Vector3(0, emisor.get_meta("altura_emision"), 0)


func establecer_activo(valor: bool) -> void:
	activo = valor
	visible = valor
	_actualizar_posicion()
	for emisor in emisores:
		emisor.emitting = valor
		if valor:
			emisor.restart()
	if descarga:
		descarga.hide()
		duracion_descarga = 0.0
	process_mode = Node.PROCESS_MODE_INHERIT if valor else Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if not activo:
		return
	_actualizar_posicion()
	if not descarga or not is_instance_valid(astronauta):
		return
	espera_descarga -= delta
	if espera_descarga <= 0:
		_crear_descarga()
		espera_descarga = azar.randf_range(7.0, 14.0)
	if duracion_descarga > 0:
		duracion_descarga -= delta
		descarga.visible = duracion_descarga > 0


func _crear_descarga() -> void:
	var angulo := azar.randf() * TAU
	var punto := to_local(astronauta.global_position) + Vector3(cos(angulo), 0, sin(angulo)) * 35.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var anterior := punto + Vector3(0, 20, 0)
	var ancho := Vector3.UP.cross(punto - to_local(astronauta.global_position)).normalized() * 0.045
	for i in 7:
		var a := anterior
		var b := punto + Vector3(azar.randf_range(-1, 1), 20.0 - (i + 1) * 2.2, 0)
		anterior = b
		for v in [a - ancho, b - ancho, b + ancho, a - ancho, b + ancho, a + ancho]:
			st.add_vertex(v)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.6, 0.9, 0.35) if perfil.efecto == "radiation" else Color(0.65, 0.75, 1.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	descarga.mesh = st.commit()
	descarga.material_override = material
	duracion_descarga = 0.22
	descarga.show()
