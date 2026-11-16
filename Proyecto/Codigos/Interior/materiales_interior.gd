@tool
extends Node

## Acabados compartidos para las instancias importadas, sin alterar sus modelos.
@export var interior: Node3D

const BASE := "res://Proyecto/Materiales/Interior/"
const VERSION_ACABADOS := 4
const VARIACION = preload(BASE + "VariacionSuave.tres")
const GRANO = preload(BASE + "MicroGrano.tres")
const SILLA = preload(BASE + "SillaCabina.tres")
const HERRAMIENTAS = preload(BASE + "Herramientas.tres")
const PANTALLA = preload(BASE + "PantallaSala.tres")
const PANELES = preload("res://Proyecto/Materiales/InteriorPaneles.tres")
const ACABADOS := {
	"metal": preload(BASE + "MetalCepillado.tres"),
	"pintura": preload(BASE + "MetalPintado.tres"),
	"plastico": preload(BASE + "Polimero.tres"),
	"tela": preload(BASE + "Tapizado.tres"),
	"ceramica": preload(BASE + "Ceramica.tres"),
}
var _materiales: Dictionary = {}


func _ready() -> void:
	call_deferred("aplicar")


func aplicar() -> void:
	if not is_instance_valid(interior):
		return
	for nodo in interior.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if not malla.mesh or malla.get_meta("conservar_material", false):
			continue
		var partes := String(interior.get_path_to(malla)).split("/")
		var grupo := "Cabina"
		if partes.size() > 1 and partes[0] == "Muebles":
			grupo = partes[1]
			if grupo == "DecoracionNave" and partes.size() > 2:
				grupo = partes[2]
		for superficie in malla.mesh.get_surface_count():
			var original := malla.get_active_material(superficie) as StandardMaterial3D
			# El editor puede guardar los overrides generados al guardar Main.
			# Renovarlos cuando cambia el acabado, en lugar de conservar versiones viejas.
			if original and original.get_meta("version_acabado", 0) == VERSION_ACABADOS:
				continue
			if malla.get_active_material(superficie) and not original:
				continue
			var clave := grupo + ":" + str(original.get_instance_id() if original else 0)
			if not _materiales.has(clave):
				var acabado := _crear_acabado(original, grupo)
				acabado.set_meta("acabado_interior", true)
				acabado.set_meta("version_acabado", VERSION_ACABADOS)
				if original:
					acabado.set_meta("material_origen", original.get_meta("material_origen", original.resource_name))
				_materiales[clave] = acabado
			malla.set_surface_override_material(superficie, _materiales[clave])


func _perfil(nombre: String, color: Color = Color(-1, -1, -1)) -> StandardMaterial3D:
	var material := ACABADOS[nombre].duplicate() as StandardMaterial3D
	if color.r >= 0.0:
		material.albedo_color = color
	return material


func _crear_acabado(original: StandardMaterial3D, grupo: String) -> StandardMaterial3D:
	if grupo in ["Cockpit Chair", "SillaAuxiliar"]:
		return SILLA.duplicate() as StandardMaterial3D
	if grupo == "Herramientas":
		return HERRAMIENTAS.duplicate() as StandardMaterial3D
	if grupo == "MesaTrabajo":
		# El escritorio importado no tiene UV: proyeccion espacial, sin estirar mapas.
		return _perfil("pintura", Color(0.34, 0.40, 0.43))
	var nombre: String = original.get_meta("material_origen", original.resource_name) if original else ""
	if grupo == "PuertaInterior":
		return _puerta(nombre)
	if grupo == "EscritorioAuxiliar":
		match nombre:
			"Emissive":
				var luz := _perfil("plastico", Color(0.16, 0.43, 0.48))
				luz.emission_enabled = true
				luz.emission = Color(0.13, 0.65, 0.75)
				luz.emission_energy_multiplier = 0.65
				return luz
			"sy_anodized_orange_matte": return _perfil("pintura", Color(0.55, 0.24, 0.07))
			"sy_rubber": return _perfil("plastico", Color(0.045, 0.055, 0.065))
			_: return _perfil("metal", Color(0.38, 0.45, 0.50))
	if grupo == "ConsolaAudio":
		return _consola_audio(original)
	if grupo == "Generador" and original and not original.albedo_texture:
		match nombre:
			"Material", "Material.002", "Material.004", "Material.005":
				return _perfil("pintura", Color(0.24, 0.30, 0.33))
			"Material.003": return _perfil("plastico")
			"Material.007": return _perfil("metal", Color(0.38, 0.44, 0.47))
			"RED_STILL": return _perfil("pintura", Color(0.40, 0.12, 0.07))
	if grupo == "SalaDescanso":
		match nombre:
			"Material": return PANTALLA.duplicate() as StandardMaterial3D
			"estructura": return PANELES.duplicate() as StandardMaterial3D
			"sofa": return _perfil("tela")
			"alfombra": return _perfil("tela", Color(0.075, 0.10, 0.12))
			"patas_sofa": return _perfil("metal", Color(0.18, 0.22, 0.25))
			"maceta": return _perfil("ceramica")
			"mueble", "caja": return _perfil("pintura", Color(0.38, 0.45, 0.48))
			"material", "Material.006": return _perfil("plastico")
			"Material.007": return _perfil("metal")
			"Material.002": return _perfil("plastico", Color(0.42, 0.10, 0.065))
			"Material.004": return _perfil("plastico", Color(0.10, 0.32, 0.19))
			"Material.005": return _perfil("pintura", Color(0.65, 0.43, 0.09))
	var material := original.duplicate() as StandardMaterial3D if original else _perfil("pintura")
	# Algunos FBX marcan todo como emisivo incluso con un color negro.
	if material.emission_enabled and not material.emission_texture and material.emission.get_luminance() < 0.001:
		material.emission_enabled = false
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Conservar los UV y canales PBR originales de cada atlas.
	if material.albedo_texture:
		material.normal_scale = minf(material.normal_scale, 0.7)
		if grupo == "Ducha" and nombre.begins_with("Concrete_tile"):
			material.metallic = 0.0
			material.roughness = 0.9
			material.normal_scale = 0.4
			material.uv1_triplanar = true
			material.uv1_world_triplanar = true
			material.uv1_scale = Vector3.ONE * 1.2
		elif grupo == "Cama" or nombre == "handduk":
			material.roughness = 0.92 if nombre != "ESTRUTUR" else 0.65
			_microdetalle(material, 0.18)
			if grupo == "Cama":
				match nombre:
					"COLCH_O": material.albedo_color = Color(0.28, 0.40, 0.49)
					"DETALHE": material.albedo_color = Color(0.12, 0.23, 0.30)
					"ESTRUTUR": material.albedo_color = Color(0.42, 0.47, 0.49)
		elif grupo == "ConsolaMando" and nombre.contains("screens"):
			material.metallic = 0.0
			material.roughness = 0.24
		elif grupo == "Estanteria":
			material.metallic = 0.8 if nombre.contains("Metal") else 0.15
			material.roughness = 0.42 if nombre.contains("Metal") else 0.6
			material.albedo_color = Color(0.48, 0.55, 0.59)
		elif grupo == "CajasCarga" and not material.roughness_texture:
			material.roughness = 0.65
		elif grupo == "Stol2":
			material.normal_scale = 0.55
			var mapa := "table" if not material.emission_enabled else "hologram_glass"
			material.ao_enabled = true
			material.ao_texture = load("res://Proyecto/Modelos/monitoring-station/textures/" + mapa + "_Mixed_AO.png")
			material.ao_light_affect = 0.3
			if mapa == "hologram_glass":
				material.metallic = 0.05
				material.roughness = 0.26
			else:
				material.albedo_color = Color(0.70, 0.76, 0.80)
	else:
		# Los materiales lisos conservan su color y reciben variacion muy sutil.
		material.albedo_texture = VARIACION
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE * 4.0
		material.metallic = minf(material.metallic, 0.4)
		material.roughness = maxf(material.roughness, 0.48)
		material.normal_enabled = true
		material.normal_texture = GRANO
		material.normal_scale = 0.06
		if grupo == "SalaDescanso" and nombre in ["hojas", "tallo", "tierra"]:
			material.metallic = 0.0
			material.roughness = 0.95
		if grupo == "Ducha":
			if nombre == "glasvgg.001" or nombre in ["flaska.003", "flaska.004"]:
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.albedo_color = Color(0.48, 0.65, 0.70, 0.22)
				material.metallic = 0.0
				material.roughness = 0.14
				material.normal_scale = 0.01
			elif nombre in ["pump.001", "svart_pump.001"]:
				material.metallic = 0.85
				material.roughness = 0.32
	if material.emission_enabled:
		material.emission_energy_multiplier = 0.45 if grupo == "Generador" else 0.7
		if not material.emission_texture:
			if grupo == "Generador":
				material.emission = Color(0.85, 0.24, 0.07)
			else:
				material.emission = Color(0.42, 0.72, 0.80)
				material.albedo_color = Color(0.55, 0.76, 0.80)
	return material


func _puerta(nombre: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = nombre
	var carpeta := "res://Proyecto/Modelos/sci-fi-door/textures/" + nombre
	material.albedo_texture = load(carpeta + "_albedo.jpeg")
	material.metallic = 1.0
	material.metallic_texture = load(carpeta + "_metallic.jpeg")
	material.roughness = 1.0
	material.roughness_texture = load(carpeta + "_roughness.jpeg")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = true
	material.normal_texture = load(carpeta + "_normal.png")
	material.normal_scale = 0.6
	material.ao_enabled = true
	material.ao_texture = load(carpeta + "_AO.jpeg")
	material.ao_light_affect = 0.3
	if nombre != "pillar" and ResourceLoader.exists(carpeta + "_emissive.jpeg"):
		material.emission_enabled = true
		material.emission = Color(0.5, 0.80, 0.9)
		material.emission_texture = load(carpeta + "_emissive.jpeg")
		material.emission_energy_multiplier = 0.35 if nombre == "emissive" else 0.12
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _consola_audio(original: StandardMaterial3D) -> StandardMaterial3D:
	var material := original.duplicate() as StandardMaterial3D
	var nombre := original.resource_name.trim_prefix("M_").trim_suffix("_Translucent")
	if nombre == "Speakers":
		nombre = "Speaker"
	var carpeta := "res://Proyecto/Modelos/killer-beats-casette-mixstation/textures/GAP_F_Blaase_Mikkel_" + nombre
	material.albedo_color = Color.WHITE
	material.emission_enabled = false
	material.normal_enabled = true
	material.normal_texture = load(carpeta + "_N.png")
	material.normal_scale = 0.55
	material.metallic = 0.0 if nombre == "Floor" else 1.0
	if nombre != "Floor":
		material.metallic_texture = load(carpeta + "_M.png")
	material.roughness = 1.0
	material.roughness_texture = load(carpeta + "_R.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.ao_enabled = true
	material.ao_texture = load(carpeta + ("_O.png" if nombre == "Floor" else "_AO.png"))
	material.ao_light_affect = 0.25
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _microdetalle(material: StandardMaterial3D, intensidad: float) -> void:
	material.detail_enabled = true
	# Con MIX y sin detalle de color, Godot mezcla blanco sobre el atlas.
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	material.detail_normal = GRANO
	material.uv2_triplanar = true
	material.uv2_world_triplanar = true
	material.uv2_scale = Vector3.ONE * 16.0
	material.normal_scale = intensidad
