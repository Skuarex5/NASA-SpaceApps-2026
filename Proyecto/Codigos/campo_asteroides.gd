extends Node3D

const ASTEROIDE_NASA: ArrayMesh = preload("res://Proyecto/Modelos/NASA/asteroide_1999_rq36_optimizado.res")

@export var nave: Node3D
@export var planetas: Node3D
@export_range(0, 3000) var cantidad: int = 900
@export var semilla: int = 2026
@export_range(200, 1000) var tamano_sector: float = 400.0
@export_range(600, 4000) var distancia_renderizado: float = 1400.0
@export_range(200, 1500) var distancia_colisiones: float = 500.0

var posiciones: Array[Vector3] = []
var radios: Array[float] = []
var exclusiones: Array[SphereShape3D] = []
var centros_planetas: Array[Vector3] = []
var sectores: Array[Dictionary] = []
var tiempo_actualizacion := 0.0


func _ready() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var centros: Array[Vector3] = [nave.global_position - nave.global_basis.z.normalized() * 350.0]
	var minimo := nave.global_position
	var maximo := minimo
	for planeta in planetas.get_children():
		if not planeta is Node3D:
			continue
		for fraccion in [0.25, 0.5, 0.75]:
			centros.append(nave.global_position.lerp(planeta.global_position, fraccion))
		minimo = minimo.min(planeta.global_position)
		maximo = maximo.max(planeta.global_position)
		var radio := 100.0
		for malla in planeta.find_children("*", "MeshInstance3D", true, false):
			var caja: AABB = malla.global_transform * malla.get_aabb()
			radio = maxf(radio, caja.size.length() * 0.5 + caja.get_center().distance_to(planeta.global_position))
		var esfera := SphereShape3D.new()
		esfera.radius = radio + 60.0
		exclusiones.append(esfera)
		centros_planetas.append(planeta.global_position)
	minimo -= Vector3(900, 350, 900)
	maximo += Vector3(900, 350, 900)
	var material := ShaderMaterial.new()
	material.shader = preload("res://Proyecto/Efectos/roca_espacial.gdshader")
	var variantes: Array[ArrayMesh] = []
	var formas: Array[ConvexPolygonShape3D] = []
	for i in 8:
		var malla: ArrayMesh = ASTEROIDE_NASA.duplicate() if i == 0 else _crear_roca(semilla + i * 97)
		malla.surface_set_material(0, material)
		variantes.append(malla)
		formas.append(malla.create_convex_shape())
	var celdas: Dictionary = {}
	var intentos := 0
	while posiciones.size() < cantidad and intentos < cantidad * 40:
		intentos += 1
		var distribucion := azar.randf()
		var punto: Vector3
		if distribucion < 0.25:
			punto = Vector3(azar.randf_range(minimo.x, maximo.x), azar.randf_range(minimo.y, maximo.y), azar.randf_range(minimo.z, maximo.z))
		else:
			var grupo := 0 if distribucion < 0.33 else azar.randi_range(1, maxi(centros.size() - 1, 1))
			grupo = mini(grupo, centros.size() - 1)
			var extension := Vector3(380, 100, 380) if grupo == 0 else Vector3(480, 220, 480)
			punto = centros[grupo] + Vector3(azar.randf_range(-1, 1), azar.randf_range(-1, 1), azar.randf_range(-1, 1)) * extension
		var radio := azar.randf_range(3.0, 18.0)
		if not _posicion_libre(punto, radio):
			continue
		var giro := Basis.from_euler(Vector3(azar.randf_range(0, TAU), azar.randf_range(0, TAU), azar.randf_range(0, TAU)))
		var escala := Vector3(azar.randf_range(0.8, 1.2), azar.randf_range(0.7, 1.2), azar.randf_range(0.8, 1.2)) * radio
		var celda := Vector3i(floori(punto.x / tamano_sector), floori(punto.y / tamano_sector), floori(punto.z / tamano_sector))
		# Compartir geometria dentro de cada sector reduce las llamadas de dibujo.
		var variante := absi(hash(celda)) % variantes.size()
		if not celdas.has(celda):
			celdas[celda] = {"centro": (Vector3(celda) + Vector3.ONE * 0.5) * tamano_sector, "rocas": []}
		var dato: Dictionary = celdas[celda]
		var transformacion := Transform3D(giro.scaled(escala), punto - dato.centro)
		dato.rocas.append({"transformacion": transformacion, "variante": variante})
		posiciones.append(punto)
		radios.append(radio)
	for celda in celdas:
		_crear_sector(celdas[celda], variantes, formas)
	_actualizar_colisiones()


func _crear_sector(dato: Dictionary, variantes: Array[ArrayMesh], formas: Array[ConvexPolygonShape3D]) -> void:
	var sector := Node3D.new()
	sector.name = "Sector%d" % sectores.size()
	sector.position = to_local(dato.centro)
	add_child(sector)
	var por_variante: Array[Array] = []
	for i in variantes.size():
		por_variante.append([])
	var cuerpos: Array[StaticBody3D] = []
	for roca in dato.rocas:
		por_variante[roca.variante].append(roca.transformacion)
		var cuerpo := StaticBody3D.new()
		cuerpo.add_to_group("asteroides")
		cuerpo.transform = roca.transformacion
		cuerpo.collision_layer = 0
		var colision := CollisionShape3D.new()
		colision.shape = formas[roca.variante]
		cuerpo.add_child(colision)
		sector.add_child(cuerpo)
		cuerpos.append(cuerpo)
	for i in variantes.size():
		if por_variante[i].is_empty():
			continue
		var instancias := MultiMesh.new()
		instancias.transform_format = MultiMesh.TRANSFORM_3D
		instancias.mesh = variantes[i]
		instancias.instance_count = por_variante[i].size()
		for j in instancias.instance_count:
			instancias.set_instance_transform(j, por_variante[i][j])
		var grupo := MultiMeshInstance3D.new()
		grupo.multimesh = instancias
		grupo.visibility_range_end = distancia_renderizado
		grupo.visibility_range_end_margin = 120.0
		grupo.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		sector.add_child(grupo)
	sectores.append({"centro": dato.centro, "cuerpos": cuerpos, "activo": false})


func _physics_process(delta: float) -> void:
	tiempo_actualizacion += delta
	if tiempo_actualizacion >= 0.1:
		tiempo_actualizacion = 0.0
		_actualizar_colisiones()


func _actualizar_colisiones() -> void:
	var velocidad: Vector3 = nave.linear_velocity
	# Anticipar el desplazamiento para que el turbo no alcance sectores sin colision.
	var radio := distancia_colisiones + velocidad.length() * 0.25 + tamano_sector * 0.87 + 30.0
	var centro := nave.global_position + velocidad * 0.05
	for sector in sectores:
		var activar: bool = nave.pilotando and centro.distance_squared_to(sector.centro) < radio * radio
		if activar == sector.activo:
			continue
		sector.activo = activar
		for cuerpo in sector.cuerpos:
			cuerpo.collision_layer = 1 if activar else 0

func _posicion_libre(punto: Vector3, radio: float) -> bool:
	if punto.distance_to(nave.global_position) < 60.0 + radio * 1.5:
		return false
	for i in exclusiones.size():
		if punto.distance_to(centros_planetas[i]) < exclusiones[i].radius + radio * 1.5:
			return false
	for i in posiciones.size():
		if punto.distance_to(posiciones[i]) < (radios[i] + radio) * 1.6:
			return false
	return true


func _crear_roca(numero: int) -> ArrayMesh:
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 18
	esfera.rings = 10
	var datos := esfera.get_mesh_arrays()
	var vertices: PackedVector3Array = datos[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = datos[Mesh.ARRAY_INDEX]
	var ruido := FastNoiseLite.new()
	ruido.seed = numero
	ruido.frequency = 1.4
	for i in vertices.size():
		var punto := vertices[i]
		vertices[i] *= 1.0 + ruido.get_noise_3dv(punto * 2.0) * 0.38
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	for indice in indices:
		superficie.add_vertex(vertices[indice])
	superficie.generate_normals()
	superficie.index()
	return superficie.commit()
