class_name DatosMision
extends Resource

@export_group("Informacion")
@export var id: String = ""
@export var titulo: String = "New mission"
@export_multiline var descripcion: String = ""

@export_group("Objetivo")
@export_range(1, 999, 1) var objetivo: int = 1
@export var mostrar_contador: bool = true

@export_group("Estado inicial")
@export var disponible_al_inicio: bool = true
