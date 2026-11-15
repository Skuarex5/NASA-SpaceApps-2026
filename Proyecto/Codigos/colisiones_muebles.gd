extends Node3D

const RUTAS_MUEBLES: Array[String] = [
	"SpaceshipInterior/Muebles/Sketchfab_Scene",
	"SpaceshipInterior/Muebles/living",
	"SpaceshipInterior/Muebles/Ducha",
]


func _ready() -> void:
	call_deferred("_crear_colisiones_muebles")


func _crear_colisiones_muebles() -> void:
	for ruta in RUTAS_MUEBLES:
		var mueble := get_node_or_null(ruta) as Node3D
		if mueble == null:
			push_warning("No se encontró el mueble para colision: " + ruta)
			continue

		var mallas := mueble.find_children("*", "MeshInstance3D", true, false)
		for nodo in mallas:
			var malla := nodo as MeshInstance3D
			if malla == null or malla.mesh == null:
				continue
			if _tiene_colision_estatica(malla):
				continue

			malla.create_trimesh_collision()


func _tiene_colision_estatica(malla: MeshInstance3D) -> bool:
	for hijo in malla.get_children():
		if hijo is StaticBody3D:
			return true
	return false
