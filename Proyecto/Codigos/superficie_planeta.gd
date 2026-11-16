extends Node3D

const TAMANO := 65
const PASO := 4.0
const MITAD := (TAMANO - 1) * PASO * 0.5
const PERFILES = preload("res://Proyecto/Codigos/Planetas/perfiles_planeta.gd")

var bioma := 0
var nombre_planeta := "Planet"
var astronauta: CharacterBody3D
var entorno: Environment
var perfil: Dictionary
var clima: Node3D
var ruido := FastNoiseLite.new()
var cuerpos: Array[CollisionObject3D] = []
var polvo_pasos: Array[GPUParticles3D] = []
var tiempo_pasos := 0.0
var siguiente_emisor := 0
var punto_nave := Vector3(0, 0.11, 0)
var punto_astronauta := Vector3(1.8, 0.08, -3.2)


func _ready() -> void:
	perfil = PERFILES.obtener(bioma)
	ruido.seed = 6031 + bioma * 873 + int(nombre_planeta.hash() % 100000)
	ruido.frequency = 0.025
	ruido.fractal_octaves = 4
	_crear_entorno()
	_crear_terreno()
	_crear_rocas()
	_crear_particulas()
	clima = preload("res://Proyecto/Codigos/Planetas/clima_planeta.gd").new()
	clima.name = "Clima"
	clima.perfil = perfil
	clima.astronauta = astronauta
	add_child(clima)


func altura(x: float, z: float) -> float:
	var distancia := Vector2(x, z).length()
	var relieve: float = ruido.get_noise_2d(x, z) * float(perfil.relieve)
	if bioma == 5:
		relieve += sin(x * 0.085 + sin(z * 0.025)) * 2.4
	elif bioma == 4:
		relieve += absf(ruido.get_noise_2d(x * 1.8, z * 1.8)) * 3.0
	if bioma == 0:
		for centro in [Vector2(-40, -30), Vector2(52, 36), Vector2(-20, 68)]:
			var d := Vector2(x, z).distance_to(centro)
			relieve -= 4.0 * exp(-d * d / 170.0)
			relieve += 1.5 * exp(-pow((d - 18.0) / 4.0, 2.0))
	# Plataforma natural y plana de aterrizaje; montanas delimitan la zona.
	relieve *= smoothstep(12.0, 24.0, distancia)
	relieve += smoothstep(MITAD - 25.0, MITAD, maxf(absf(x), absf(z))) * 22.0
	return relieve


func _material_roca() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://Proyecto/Efectos/terreno_planeta.gdshader")
	material.set_shader_parameter("color_oscuro", Vector3(perfil.oscuro.r, perfil.oscuro.g, perfil.oscuro.b))
	material.set_shader_parameter("color_claro", Vector3(perfil.claro.r, perfil.claro.g, perfil.claro.b))
	material.set_shader_parameter("rugosidad", perfil.rugosidad)
	material.set_shader_parameter("color_emision", Vector3(perfil.emision.r, perfil.emision.g, perfil.emision.b))
	material.set_shader_parameter("brillo_mineral", perfil.brillo)
	return material


func _crear_terreno() -> void:
	var alturas := PackedFloat32Array()
	alturas.resize(TAMANO * TAMANO)
	for z in TAMANO:
		for x in TAMANO:
			alturas[z * TAMANO + x] = altura(x * PASO - MITAD, z * PASO - MITAD)
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in TAMANO - 1:
		for x in TAMANO - 1:
			for esquina in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]:
				var px: int = x + esquina.x
				var pz: int = z + esquina.y
				superficie.add_vertex(Vector3(px * PASO - MITAD, alturas[pz * TAMANO + px], pz * PASO - MITAD))
	superficie.generate_normals()
	superficie.index()
	var malla := MeshInstance3D.new()
	malla.name = "Terreno"
	malla.mesh = superficie.commit()
	malla.material_override = _material_roca()
	add_child(malla)
	var forma := HeightMapShape3D.new()
	forma.map_width = TAMANO
	forma.map_depth = TAMANO
	forma.map_data = alturas
	var suelo := StaticBody3D.new()
	suelo.name = "Suelo"
	var colision := CollisionShape3D.new()
	colision.shape = forma
	colision.scale = Vector3(PASO, 1, PASO)
	suelo.add_child(colision)
	add_child(suelo)
	cuerpos.append(suelo)
	for eje in [0, 2]:
		for lado in [-1, 1]:
			var limite := StaticBody3D.new()
			limite.position[eje] = lado * (MITAD - 2)
			limite.position.y = 25
			var pared := BoxShape3D.new()
			pared.size = Vector3(3, 80, MITAD * 2) if eje == 0 else Vector3(MITAD * 2, 80, 3)
			var borde := CollisionShape3D.new()
			borde.shape = pared
			limite.add_child(borde)
			add_child(limite)
			cuerpos.append(limite)


func _crear_rocas() -> void:
	var generador := preload("res://Proyecto/Codigos/campo_asteroides.gd").new()
	var azar := RandomNumberGenerator.new()
	azar.seed = ruido.seed + 121
	var material := _material_roca()
	var variantes: Array[ArrayMesh] = []
	var formas: Array[ConvexPolygonShape3D] = []
	for i in 4:
		var roca: ArrayMesh = generador._crear_roca(183 + i + bioma * 27)
		roca.surface_set_material(0, material)
		variantes.append(roca)
		formas.append(roca.create_convex_shape())
	generador.free()
	for i in 85:
		var x := azar.randf_range(-105, 105)
		var z := azar.randf_range(-105, 105)
		if Vector2(x,z).length() < 16:
			continue
		var indice := i % variantes.size()
		var escala := Vector3.ONE * azar.randf_range(0.4, 2.2)
		var giro := Basis.from_euler(Vector3(azar.randf(), azar.randf() * TAU, azar.randf()))
		var transformacion := Transform3D(giro.scaled(escala), Vector3(x, altura(x,z) + escala.y * 0.25, z))
		var roca := MeshInstance3D.new()
		roca.mesh = variantes[indice]
		roca.transform = transformacion
		roca.visibility_range_end = 140
		add_child(roca)
		var cuerpo := StaticBody3D.new()
		cuerpo.transform = transformacion
		var colision := CollisionShape3D.new()
		colision.shape = formas[indice]
		cuerpo.add_child(colision)
		add_child(cuerpo)
		cuerpos.append(cuerpo)


func _crear_entorno() -> void:
	entorno = Environment.new()
	entorno.tonemap_mode = Environment.TONE_MAPPER_AGX
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.65, 0.72, 0.85) if bioma == 0 else perfil.horizonte.lightened(0.3)
	entorno.ambient_light_energy = 0.4
	entorno.ssao_enabled = true
	entorno.ssao_radius = 0.5
	entorno.ssao_intensity = 1.2
	entorno.glow_enabled = true
	entorno.glow_intensity = 0.25
	entorno.sky = Sky.new()
	if bioma == 0:
		var cielo := PanoramaSkyMaterial.new()
		cielo.panorama = preload("res://Proyecto/Texturas/8k_stars_milky_way.jpg")
		entorno.sky.sky_material = cielo
	else:
		var cielo := ProceduralSkyMaterial.new()
		cielo.sky_top_color = perfil.cielo
		cielo.sky_horizon_color = perfil.horizonte
		cielo.ground_horizon_color = perfil.horizonte.darkened(0.15)
		cielo.ground_bottom_color = perfil.oscuro
		entorno.sky.sky_material = cielo
	entorno.background_mode = Environment.BG_SKY
	entorno.fog_enabled = float(perfil.niebla) > 0.0
	entorno.fog_density = perfil.niebla
	entorno.fog_light_color = perfil.horizonte
	entorno.fog_light_energy = 0.65
	var sol := DirectionalLight3D.new()
	sol.name = "SolSuperficie"
	sol.rotation_degrees = Vector3(-35, -40, 0)
	sol.light_color = Color(1, 0.96, 0.88) if bioma == 0 else perfil.horizonte.lightened(0.65)
	sol.light_energy = 1.7 if bioma == 0 else 1.25
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 100
	add_child(sol)


func _crear_particulas() -> void:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(perfil.claro.r, perfil.claro.g, perfil.claro.b, 0.35)
	var mota := SphereMesh.new()
	mota.radius = 0.007
	mota.height = 0.014
	mota.radial_segments = 6
	mota.rings = 3
	mota.material = material
	for i in 3:
		var emisor := GPUParticles3D.new()
		emisor.amount = 12
		emisor.lifetime = 0.9
		emisor.one_shot = true
		emisor.emitting = false
		emisor.local_coords = false
		emisor.draw_pass_1 = mota
		var proceso := ParticleProcessMaterial.new()
		proceso.gravity = Vector3(0, -float(perfil.gravedad), 0)
		proceso.direction = Vector3.UP
		proceso.spread = 65
		proceso.initial_velocity_min = 0.2
		proceso.initial_velocity_max = 0.6
		emisor.process_material = proceso
		add_child(emisor)
		polvo_pasos.append(emisor)
	if bioma in [1, 6]:
		for posicion_ventilacion in [Vector3(-15,0,-20), Vector3(20,0,12), Vector3(-25,0,30)]:
			_crear_ventilacion(posicion_ventilacion)


func _crear_ventilacion(punto: Vector3) -> void:
	var emisor := GPUParticles3D.new()
	emisor.position = Vector3(punto.x, altura(punto.x,punto.z) + 0.2, punto.z)
	emisor.amount = 22
	emisor.lifetime = 4.0
	emisor.preprocess = 4.0
	var proceso := ParticleProcessMaterial.new()
	proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proceso.emission_sphere_radius = 0.6
	proceso.direction = Vector3.UP
	proceso.spread = 25
	proceso.initial_velocity_min = 0.15
	proceso.initial_velocity_max = 0.65
	proceso.gravity = Vector3(0, 0.015, 0)
	proceso.scale_min = 0.5
	proceso.scale_max = 1.2
	emisor.process_material = proceso
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.18, 0.025)
	material.emission_enabled = true
	material.emission = Color(1, 0.18, 0.015)
	material.emission_energy_multiplier = 2.0
	var mota := SphereMesh.new()
	mota.radius = 0.025
	mota.height = 0.05
	mota.radial_segments = 6
	mota.rings = 3
	mota.material = material
	emisor.draw_pass_1 = mota
	add_child(emisor)


func _physics_process(delta: float) -> void:
	if astronauta == null:
		return
	tiempo_pasos -= delta
	if tiempo_pasos <= 0 and astronauta.is_on_floor() and Vector2(astronauta.velocity.x, astronauta.velocity.z).length() > 0.4:
		var emisor := polvo_pasos[siguiente_emisor]
		emisor.global_position = astronauta.global_position + Vector3(0,0.06,0)
		emisor.restart()
		emisor.emitting = true
		siguiente_emisor = (siguiente_emisor + 1) % polvo_pasos.size()
		tiempo_pasos = 0.38


func establecer_activa(activa: bool) -> void:
	visible = activa
	process_mode = Node.PROCESS_MODE_INHERIT if activa else Node.PROCESS_MODE_DISABLED
	clima.establecer_activo(activa)
	for particulas in find_children("*", "GPUParticles3D", true, false):
		if not clima.is_ancestor_of(particulas):
			particulas.emitting = activa and not particulas.one_shot
	for cuerpo in cuerpos:
		cuerpo.collision_layer = 1 if activa else 0
