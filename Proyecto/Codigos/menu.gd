
extends Control

@export_file("*.tscn")
var escena_juego: String = "res://Proyecto/Escenas/Main.tscn"

@onready var boton_play: TextureButton = $MenuButtons/Play
@onready var boton_settings: TextureButton = $MenuButtons/Settings
@onready var boton_credits: TextureButton = $MenuButtons/Credits
@onready var boton_exit: TextureButton = $MenuButtons/Exit

@onready var musica: AudioStreamPlayer2D = $AudioStreamPlayer

var ventana_opciones: AcceptDialog
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
	ventana_opciones = AcceptDialog.new()
	ventana_opciones.title = "Options"
	ventana_opciones.ok_button_text = "Back"
	add_child(ventana_opciones)

	var contenido := VBoxContainer.new()
	contenido.custom_minimum_size = Vector2(350, 130)
	contenido.add_theme_constant_override("separation", 15)
	ventana_opciones.add_child(contenido)

	# CONTROL DE VOLUMEN
	var texto_volumen := Label.new()
	texto_volumen.text = "Master Volume"
	contenido.add_child(texto_volumen)

	var volumen := HSlider.new()
	volumen.min_value = 0
	volumen.max_value = 100
	volumen.step = 1
	volumen.custom_minimum_size = Vector2(340, 25)

	volumen.value = (
		db_to_linear(AudioServer.get_bus_volume_db(0)) * 100.0
	)

	if AudioServer.is_bus_mute(0):
		volumen.value = 0.0

	volumen.value_changed.connect(_cambiar_volumen)
	contenido.add_child(volumen)

	# PANTALLA COMPLETA
	var pantalla_completa := CheckButton.new()
	pantalla_completa.text = "Fullscreen"

	pantalla_completa.button_pressed = (
		DisplayServer.window_get_mode()
		== DisplayServer.WINDOW_MODE_FULLSCREEN
	)

	pantalla_completa.toggled.connect(_cambiar_pantalla)
	contenido.add_child(pantalla_completa)

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
		+ "NASA 3D Resources (optimized for gameplay)."
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
	ventana_opciones.popup_centered(Vector2i(440, 250))


func _cambiar_volumen(valor: float) -> void:
	var volumen_lineal: float = valor / 100.0

	AudioServer.set_bus_mute(0, valor <= 0.0)

	AudioServer.set_bus_volume_db(
		0,
		linear_to_db(maxf(volumen_lineal, 0.001))
	)


func _cambiar_pantalla(activado: bool) -> void:
	if activado:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)


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
