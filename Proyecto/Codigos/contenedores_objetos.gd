extends RefCounted

signal cambiado

var mochila: Array[Dictionary] = []
var revision := 0


func _init(capacidad: int = 12) -> void:
	for i in capacidad:
		mochila.append({})


func contenedor(_nombre: String) -> Array[Dictionary]:
	return mochila


func preparar_equipo(equipo: Array[Dictionary]) -> Dictionary:
	var propuesta: Array[Dictionary] = mochila.duplicate(true)
	for objeto in equipo:
		var existente := false
		for slot in propuesta:
			if slot.get("id") == objeto.id:
				slot.merge(objeto, true)
				existente = true
				break
		if not existente and not _insertar(propuesta, objeto):
			return {}
	return {"mochila": propuesta}


func aplicar(distribucion: Dictionary) -> void:
	mochila = distribucion.mochila
	_notificar()


func agregar_recurso(id: String, nombre: String, cantidad: int, icono: Texture2D = null, peso: float = 0, planeta: String = "") -> bool:
	if id.is_empty() or nombre.is_empty() or cantidad <= 0 or peso < 0:
		return false
	var propuesta: Array[Dictionary] = mochila.duplicate(true)
	var objeto := {"id": "recurso:" + id, "nombre": nombre, "cantidad": cantidad,
		"icono": icono, "peso": peso, "planeta": planeta, "tipo": "recurso", "max_apilado": 100}
	if not _insertar(propuesta, objeto):
		return false
	mochila = propuesta
	_notificar()
	return true


func _insertar(slots: Array[Dictionary], objeto: Dictionary) -> bool:
	var restante: int = objeto.cantidad
	var limite: int = objeto.max_apilado
	for existente in slots:
		if existente.get("id") == objeto.id:
			var transferir := mini(restante, maxi(0, limite - int(existente.cantidad)))
			existente.cantidad += transferir
			restante -= transferir
	for i in slots.size():
		if restante <= 0:
			return true
		if slots[i].is_empty():
			slots[i] = objeto.duplicate(true)
			slots[i].cantidad = mini(restante, limite)
			restante -= int(slots[i].cantidad)
	return restante == 0


func datos_arrastre(origen: String, indice: int) -> Dictionary:
	if origen != "mochila" or indice < 0 or indice >= mochila.size():
		return {}
	if contenedor(origen)[indice].is_empty():
		return {}
	return {"modelo": self, "origen": origen, "indice": indice, "revision": revision}


func puede_mover(datos: Variant, destino: String, indice: int) -> bool:
	if not datos is Dictionary or datos.get("modelo") != self or datos.get("revision") != revision:
		return false
	if destino != "mochila" or indice < 0 or indice >= mochila.size():
		return false
	var origen: String = datos.get("origen", "")
	var posicion: int = datos.get("indice", -1)
	if datos_arrastre(origen, posicion).is_empty() or (origen == destino and posicion == indice):
		return false
	var desde := contenedor(origen)[posicion]
	var hacia := contenedor(destino)[indice]
	return hacia.is_empty() or hacia.id != desde.id or int(hacia.cantidad) < int(hacia.max_apilado)


func mover(datos: Variant, destino: String, indice: int) -> bool:
	if not puede_mover(datos, destino, indice):
		return false
	var origen: Array[Dictionary] = contenedor(datos.origen)
	var llegada: Array[Dictionary] = contenedor(destino)
	var desde := origen[int(datos.indice)]
	var hacia := llegada[indice]
	if not hacia.is_empty() and hacia.id == desde.id:
		var cantidad := mini(int(desde.cantidad), int(hacia.max_apilado) - int(hacia.cantidad))
		hacia.cantidad += cantidad
		desde.cantidad -= cantidad
		if desde.cantidad == 0:
			origen[int(datos.indice)] = {}
	else:
		llegada[indice] = desde
		origen[int(datos.indice)] = hacia
	_notificar()
	return true


func peso_restante(ids_seleccionados: Array[String]) -> float:
	var total := 0.0
	for objeto in mochila:
		if not objeto.is_empty() and objeto.id not in ids_seleccionados:
			total += float(objeto.peso) * int(objeto.cantidad)
	return total


func _notificar() -> void:
	revision += 1
	cambiado.emit()
