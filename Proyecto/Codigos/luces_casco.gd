extends BoneAttachment3D

@export var astronauta: CharacterBody3D
@export var malla: MeshInstance3D
@export var encendidas: bool = true

@onready var izquierda: SpotLight3D = $LuzIzquierda
@onready var derecha: SpotLight3D = $LuzDerecha

var material_lamparas: StandardMaterial3D


func _ready() -> void:
	# El material se duplica para cambiar solo las lamparas de este astronauta.
	material_lamparas = malla.get_active_material(11).duplicate() as StandardMaterial3D
	malla.set_surface_override_material(11, material_lamparas)
	_actualizar_luces()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or not astronauta.is_physics_processing() or not is_visible_in_tree():
		return
	if event.is_action_pressed("luces_casco") and not event.is_echo():
		encendidas = not encendidas
		_actualizar_luces()
		get_viewport().set_input_as_handled()


func _actualizar_luces() -> void:
	izquierda.visible = encendidas
	derecha.visible = encendidas
	material_lamparas.emission_enabled = encendidas
