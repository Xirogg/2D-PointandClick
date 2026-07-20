extends Node

# Persistent player settings (window mode, audio, language).
# Autoload: loaded + applied once at startup, saved when the settings menu closes.
# Values are kept here (not in the menu) so they survive scene changes and restarts.

const CONFIG_PATH := "user://settings.cfg"

# Locales offered in the settings menu. Global.checklanguage() reads the locale
# back out of the TranslationServer, so switching here drives the whole game.
const LOCALES: PackedStringArray = ["de", "en"]

var fullscreen: bool = false
var vsync: bool = true
var master_volume: float = 1.0 ### linear 0.0 .. 1.0, not decibels
var locale: String = "de"


func _ready() -> void:
	load_settings()
	apply_all()


func apply_all() -> void:
	set_fullscreen(fullscreen)
	set_vsync(vsync)
	set_master_volume(master_volume)
	set_locale(locale)


# --- Individual settings -------------------------------------------

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func set_vsync(enabled: bool) -> void:
	vsync = enabled
	var mode := DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var bus := AudioServer.get_bus_index("Master")
	# linear_to_db(0.0) is -INF, so mute instead of feeding that to the bus.
	AudioServer.set_bus_mute(bus, is_zero_approx(master_volume))
	if not is_zero_approx(master_volume):
		AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume))


func set_locale(new_locale: String) -> void:
	locale = new_locale if new_locale in LOCALES else LOCALES[0]
	TranslationServer.set_locale(locale)


# --- Persistence ---------------------------------------------------

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "vsync", vsync)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("game", "locale", locale)

	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("GameSettings: could not save %s (error %d)" % [CONFIG_PATH, error])


func load_settings() -> void:
	var config := ConfigFile.new()
	# No file yet on a first launch -> keep the defaults above.
	if config.load(CONFIG_PATH) != OK:
		return

	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	vsync = config.get_value("display", "vsync", vsync)
	master_volume = config.get_value("audio", "master_volume", master_volume)
	locale = config.get_value("game", "locale", locale)
