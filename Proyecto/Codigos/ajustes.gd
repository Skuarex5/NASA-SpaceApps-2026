extends Node

const PREDETERMINADOS = {
	"modo_pantalla": 4, "resolucion": Vector2i(1280, 720), "vsync": 1, "fps": 60,
	"calidad": 2, "escala_3d": 1.0, "msaa": 2, "taa": true,
	"sombras": true, "ssao": true, "ssr": true, "glow": true,
	"distancia_asteroides": 1400.0, "volumen": 100.0, "musica": 100.0, "ambiente": 100.0,
	"sensibilidad_personaje": 1.0, "sensibilidad_nave": 1.0,
	"invertir_personaje": true, "invertir_nave": false
}
const PERFILES = [
	{"escala_3d": 0.7, "msaa": 0, "taa": false, "sombras": false, "ssao": false, "ssr": false, "glow": false, "distancia_asteroides": 800.0},
	{"escala_3d": 0.85, "msaa": 1, "taa": false, "sombras": true, "ssao": true, "ssr": false, "glow": true, "distancia_asteroides": 1000.0},
	{"escala_3d": 1.0, "msaa": 2, "taa": true, "sombras": true, "ssao": true, "ssr": true, "glow": true, "distancia_asteroides": 1400.0}
]

var valores: Dictionary = PREDETERMINADOS.duplicate(true)
var ruta_config := "user://ajustes.cfg"


func _ready() -> void:
	TranslationServer.set_locale("en")
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Musica", "Ambiente"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	cargar()
	aplicar(valores, false)
	get_tree().node_added.connect(_nodo_agregado)
	_aplicar_arbol.call_deferred()


func cargar() -> void:
	var archivo := ConfigFile.new()
	if archivo.load(ruta_config) != OK:
		return
	var guardados := PREDETERMINADOS.duplicate(true)
	for clave in guardados:
		guardados[clave] = archivo.get_value("ajustes", clave, guardados[clave])
	valores = _validar(guardados)


func _validar(datos: Dictionary) -> Dictionary:
	var resultado := PREDETERMINADOS.duplicate(true)
	for clave in resultado:
		var valor: Variant = datos.get(clave, resultado[clave])
		if typeof(valor) == typeof(resultado[clave]) or (valor is float and resultado[clave] is int) or (valor is int and resultado[clave] is float):
			resultado[clave] = valor
	for clave in ["sombras", "ssao", "ssr", "glow", "taa", "invertir_personaje", "invertir_nave"]:
		resultado[clave] = bool(resultado[clave])
	for clave in ["volumen", "musica", "ambiente"]:
		resultado[clave] = clampf(float(resultado[clave]), 0, 100)
	for clave in ["sensibilidad_personaje", "sensibilidad_nave"]:
		resultado[clave] = clampf(float(resultado[clave]), 0.25, 2.5)
	resultado.escala_3d = clampf(float(resultado.escala_3d), 0.5, 1.0)
	resultado.distancia_asteroides = clampf(float(resultado.distancia_asteroides), 600, 2000)
	resultado.msaa = clampi(int(resultado.msaa), 0, 3)
	resultado.calidad = clampi(int(resultado.calidad), 0, 3)
	resultado.vsync = clampi(int(resultado.vsync), 0, 2)
	if resultado.modo_pantalla not in [0, 3, 4]:
		resultado.modo_pantalla = 4
	if resultado.fps not in [0, 30, 60, 120, 144, 240]:
		resultado.fps = 60
	var resolucion: Vector2i = resultado.resolucion
	resultado.resolucion = Vector2i(clampi(resolucion.x, 960, 3840), clampi(resolucion.y, 540, 2160))
	return resultado


func aplicar(datos: Dictionary, guardar: bool = true) -> Error:
	valores = _validar(datos)
	Engine.max_fps = int(valores.fps)
	var ventana := get_tree().root
	ventana.msaa_3d = int(valores.msaa)
	ventana.use_taa = valores.taa
	ventana.scaling_3d_scale = valores.escala_3d
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(int(valores.modo_pantalla))
		if valores.modo_pantalla == DisplayServer.WINDOW_MODE_WINDOWED:
			var tamano: Vector2i = valores.resolucion
			var disponible := DisplayServer.screen_get_usable_rect().size
			tamano = tamano.min(disponible)
			DisplayServer.window_set_size(tamano)
			DisplayServer.window_set_position(DisplayServer.screen_get_usable_rect().position + (disponible - tamano) / 2)
		DisplayServer.window_set_vsync_mode(int(valores.vsync))
	_aplicar_volumen("Master", valores.volumen)
	_aplicar_volumen("Musica", valores.musica)
	_aplicar_volumen("Ambiente", valores.ambiente)
	_aplicar_arbol()
	if guardar:
		var archivo := ConfigFile.new()
		for clave in valores:
			archivo.set_value("ajustes", clave, valores[clave])
		return archivo.save(ruta_config)
	return OK


func _aplicar_volumen(bus: String, volumen: float) -> void:
	var indice := AudioServer.get_bus_index(bus)
	if indice >= 0:
		AudioServer.set_bus_mute(indice, volumen <= 0)
		AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(volumen / 100.0, 0.0001)))


func _aplicar_arbol() -> void:
	for nodo in get_tree().root.find_children("*", "", true, false):
		_aplicar_nodo(nodo)


func _nodo_agregado(nodo: Node) -> void:
	if nodo is WorldEnvironment or nodo is Camera3D or nodo is Light3D or nodo.get_script() != null:
		_aplicar_nodo.call_deferred(nodo)


func _aplicar_entorno(entorno: Environment) -> void:
	if entorno == null:
		return
	if not entorno.has_meta("efectos_originales"):
		entorno.set_meta("efectos_originales", {"ssao": entorno.ssao_enabled, "ssr": entorno.ssr_enabled, "glow": entorno.glow_enabled})
	var original: Dictionary = entorno.get_meta("efectos_originales")
	entorno.ssao_enabled = valores.ssao and original.ssao
	entorno.ssr_enabled = valores.ssr and original.ssr
	entorno.glow_enabled = valores.glow and original.glow


func _aplicar_nodo(nodo: Node) -> void:
	if not is_instance_valid(nodo) or nodo.is_queued_for_deletion() or not nodo.is_node_ready():
		return
	if nodo is WorldEnvironment or nodo is Camera3D:
		_aplicar_entorno(nodo.environment)
	if nodo is Light3D:
		if not nodo.has_meta("sombras_originales"):
			nodo.set_meta("sombras_originales", nodo.shadow_enabled)
		nodo.shadow_enabled = valores.sombras and nodo.get_meta("sombras_originales")
	var codigo := nodo.get_script() as Script
	if codigo == null:
		return
	var ruta := codigo.resource_path.get_file()
	if ruta in ["jugador.gd", "nave.gd"]:
		var personaje := ruta == "jugador.gd"
		if not nodo.has_meta("sensibilidad_original"):
			nodo.set_meta("sensibilidad_original", nodo.sensibilidad_mouse)
		nodo.sensibilidad_mouse = float(nodo.get_meta("sensibilidad_original")) * float(valores.sensibilidad_personaje if personaje else valores.sensibilidad_nave)
		nodo.invertir_camara_vertical = valores.invertir_personaje if personaje else valores.invertir_nave
	elif ruta.ends_with("superficie_planeta.gd"):
		_aplicar_entorno(nodo.entorno)
	elif ruta.ends_with("campo_asteroides.gd"):
		nodo.distancia_renderizado = valores.distancia_asteroides
		for grupo in nodo.find_children("*", "MultiMeshInstance3D", true, false):
			grupo.visibility_range_end = valores.distancia_asteroides
