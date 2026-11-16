extends RefCounted

# La misma paleta identifica cada mundo desde la orbita y al aterrizar.
const PERFILES := [
	{"clima": "Clear vacuum", "efecto": "clear", "oscuro": Color("24262b"), "claro": Color("777773"), "cielo": Color("050912"), "horizonte": Color("131c2c"), "niebla": 0.0, "gravedad": 3.7, "relieve": 5.0},
	{"clima": "Volcanic fallout", "efecto": "ash", "oscuro": Color("2e1009"), "claro": Color("8c401a"), "cielo": Color("1f0e0c"), "horizonte": Color("9e401a"), "niebla": 0.005, "gravedad": 8.0, "relieve": 9.0},
	{"clima": "Rain", "efecto": "rain", "oscuro": Color("152a29"), "claro": Color("496352"), "cielo": Color("192c3c"), "horizonte": Color("667d83"), "niebla": 0.012, "gravedad": 9.3, "relieve": 7.0, "rugosidad": 0.42},
	{"clima": "Radioactive storm", "efecto": "radiation", "oscuro": Color("162319"), "claro": Color("596332"), "cielo": Color("111e11"), "horizonte": Color("677d32"), "niebla": 0.019, "gravedad": 5.8, "relieve": 10.0, "brillo": 0.22, "emision": Color("72bf36")},
	{"clima": "Blizzard", "efecto": "snow", "oscuro": Color("5e7f91"), "claro": Color("d0e4e8"), "cielo": Color("405d74"), "horizonte": Color("a3becb"), "niebla": 0.018, "gravedad": 4.8, "relieve": 8.0},
	{"clima": "Sandstorm", "efecto": "sand", "oscuro": Color("61391d"), "claro": Color("b78b4c"), "cielo": Color("352519"), "horizonte": Color("ae7944"), "niebla": 0.024, "gravedad": 6.2, "relieve": 6.0},
	{"clima": "Ash and embers", "efecto": "ash", "oscuro": Color("1d2025"), "claro": Color("575256"), "cielo": Color("191820"), "horizonte": Color("706063"), "niebla": 0.014, "gravedad": 7.1, "relieve": 11.0},
	{"clima": "Ion storm", "efecto": "ion", "oscuro": Color("201d39"), "claro": Color("635678"), "cielo": Color("15152d"), "horizonte": Color("62548d"), "niebla": 0.011, "gravedad": 3.4, "relieve": 12.0, "brillo": 0.12, "emision": Color("7786e8")},
]


static func obtener(indice: int) -> Dictionary:
	var perfil: Dictionary = PERFILES[clampi(indice, 0, PERFILES.size() - 1)].duplicate()
	perfil.get_or_add("rugosidad", 0.92)
	perfil.get_or_add("brillo", 0.0)
	perfil.get_or_add("emision", Color.BLACK)
	return perfil
