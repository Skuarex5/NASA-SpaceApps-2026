
extends Control

@export_file("*.tscn")
var escena_juego: String = "res://Proyecto/Escenas/Main.tscn"

@onready var boton_play: TextureButton = $MenuButtons/Play
@onready var boton_settings: TextureButton = $MenuButtons/Settings
@onready var boton_credits: TextureButton = $MenuButtons/Credits
@onready var boton_exit: TextureButton = $MenuButtons/Exit

@onready var musica: AudioStreamPlayer2D = $AudioStreamPlayer

var ventana_opciones: Control
var ventana_creditos: AcceptDialog
var ventana_salida: ConfirmationDialog


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	# INICIAR MUSICA DEL MENU
	if not musica.playing:
		musica.play()

	# CONECTAR BOTONES
	boton_play.pressed.connect(_jugar)
	boton_settings.pressed.connect(_abrir_opciones)
	boton_credits.pressed.connect(_abrir_creditos)
	boton_exit.pressed.connect(_confirmar_salida)

	crear_ventanas()


# =====================================
# PLAY
# =====================================

func _jugar() -> void:
	if not ResourceLoader.exists(escena_juego):
		push_error("No existe la escena: " + escena_juego)
		return

	# DETENER MUSICA DEL MENU
	musica.stop()

	# CARGAR ESCENA DEL JUEGO
	get_tree().change_scene_to_file(escena_juego)


# =====================================
# CREAR VENTANAS
# =====================================

func crear_ventanas() -> void:

	# OPCIONES
	ventana_opciones = Control.new()
	ventana_opciones.set_script(preload("res://Proyecto/Codigos/menu_opciones.gd"))
	add_child(ventana_opciones)

	# CREDITOS
	ventana_creditos = AcceptDialog.new()
	ventana_creditos.title = "Credits"
	ventana_creditos.ok_button_text = "Back"

	ventana_creditos.dialog_text = (
		"SPACE EXPLORER\n\n"
		+ "Educational Space Exploration Game\n\n"
		+ "Explore, Learn and Discover\n\n"
		+ "Developed by UruBots\n\n"
		+ "Images generated using artificial intelligence (AI).\n\n"
		+ "Asteroid 1999 RQ36 model:\n"
		+ "NASA / Christopher R. Meaney\n"
		+ "NASA 3D Resources (optimized for gameplay).\n\n"
		+ "Additional 3D model credits and licenses:\n"
		+ "Proyecto/Modelos/RECURSOS_INCORPORADOS.md"
	)

	add_child(ventana_creditos)

	# CONFIRMAR SALIDA
	ventana_salida = ConfirmationDialog.new()
	ventana_salida.title = "Quit Game"
	ventana_salida.dialog_text = (
		"Are you sure you want to quit?"
	)
	ventana_salida.ok_button_text = "Quit"
	ventana_salida.confirmed.connect(_salir)

	add_child(ventana_salida)


# =====================================
# OPTIONS
# =====================================

func _abrir_opciones() -> void:
	ventana_opciones.abrir()


# =====================================
# CREDITS
# =====================================

func _abrir_creditos() -> void:
	ventana_creditos.popup_centered(Vector2i(450, 280))


# =====================================
# QUIT
# =====================================

func _confirmar_salida() -> void:
	ventana_salida.popup_centered()


func _salir() -> void:
	musica.stop()
	get_tree().quit()
