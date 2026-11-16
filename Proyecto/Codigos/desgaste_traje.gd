extends Node

const DESGASTE = preload("res://Proyecto/Efectos/desgaste_traje.gdshader")

@export var esqueleto: Skeleton3D
@export_range(0.0, 1.0, 0.05) var intensidad_suciedad: float = 0.45
@export_range(0.0, 1.0, 0.05) var intensidad_desgaste: float = 0.45


func _ready() -> void:
	for malla in esqueleto.get_children():
		if not malla is MeshInstance3D:
			continue
		for indice in malla.mesh.get_surface_count():
			var original := malla.get_active_material(indice) as StandardMaterial3D
			if original == null or original.resource_name.begins_with("Indicadores"):
				continue
			var material := original.duplicate() as StandardMaterial3D
			var capa := ShaderMaterial.new()
			capa.shader = DESGASTE
			var nombre := original.resource_name.to_lower()
			var intensidad := 0.92
			var abrasion := 0.45
			if "visor" in nombre:
				intensidad = 0.20
				abrasion = 0.28
			elif "instrumentos" in nombre:
				intensidad = 0.23
				abrasion = 0.25
			elif "goma" in nombre or "correas" in nombre or "recesses" in nombre:
				intensidad = 0.75
				capa.set_shader_parameter("color_polvo", Color(0.46, 0.40, 0.30))
				capa.set_shader_parameter("color_roce", Color(0.39, 0.37, 0.32))
			elif "metal" in nombre or "aluminio" in nombre:
				intensidad = 0.78
				abrasion = 0.65
				capa.set_shader_parameter("color_roce", Color(0.68, 0.70, 0.70))
			elif "casco" in nombre:
				abrasion = 0.70
				capa.set_shader_parameter("color_roce", Color(0.38, 0.39, 0.37))
			capa.set_shader_parameter("suciedad", intensidad * intensidad_suciedad)
			capa.set_shader_parameter("desgaste", abrasion * intensidad_desgaste)
			material.next_pass = capa
			malla.set_surface_override_material(indice, material)
