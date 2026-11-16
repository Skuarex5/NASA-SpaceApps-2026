extends Node3D

# Geometria fisica horneada a partir de los modelos, sin recalcularla al jugar.
# Las formas usan coordenadas de DecoracionNave para evitar escalas deformadas.
const FORMAS = {
	"Ducha": preload("res://Proyecto/Modelos/Muebles/Colisiones/ducha.res"),
	"SalaDescanso": preload("res://Proyecto/Modelos/Muebles/Colisiones/sala_descanso.res"),
	"Cama": preload("res://Proyecto/Modelos/Muebles/Colisiones/cama.res"),
	"ConsolaMando": preload("res://Proyecto/Modelos/Muebles/Colisiones/consola_mando.res"),
	"Computadora": preload("res://Proyecto/Modelos/Muebles/Colisiones/computadora.res"),
	"SillaAuxiliar": preload("res://Proyecto/Modelos/Muebles/Colisiones/silla_auxiliar.res"),
	"MesaTrabajo": preload("res://Proyecto/Modelos/Muebles/Colisiones/mesa_trabajo.res"),
	"Herramientas": preload("res://Proyecto/Modelos/Muebles/Colisiones/herramientas.res"),
	"ContenedorHerramientas": preload("res://Proyecto/Modelos/Muebles/Colisiones/contenedor_herramientas.res"),
	"SillaTecnica": preload("res://Proyecto/Modelos/Muebles/Colisiones/silla_tecnica.res"),
	"CajasCarga": preload("res://Proyecto/Modelos/Muebles/Colisiones/cajas_carga.res"),
	"Estanteria": preload("res://Proyecto/Modelos/Muebles/Colisiones/estanteria.res"),
	"ConsolaAudio": preload("res://Proyecto/Modelos/Muebles/Colisiones/consola_audio.res"),
	"EscritorioAuxiliar": preload("res://Proyecto/Modelos/Muebles/Colisiones/escritorio_auxiliar.res"),
	"LamparaEscritorio": preload("res://Proyecto/Modelos/Muebles/Colisiones/lampara_escritorio.res"),
	"PuertaInterior": preload("res://Proyecto/Modelos/Muebles/Colisiones/puerta_interior.res"),
	"ComputadoraRetro": preload("res://Proyecto/Modelos/Muebles/Colisiones/computadora_retro.res"),
	"Generador": preload("res://Proyecto/Modelos/Muebles/Colisiones/generador.res")
}


func _ready() -> void:
	for nombre in FORMAS:
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Colision" + nombre
		var colision := CollisionShape3D.new()
		colision.shape = FORMAS[nombre]
		cuerpo.add_child(colision)
		add_child(cuerpo)
