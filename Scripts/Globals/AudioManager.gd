extends Node

## Central sound-effects playback.
##
## Autoloaded, so a single node owns every AudioStreamPlayer and sound keeps
## going across scene changes. Two jobs:
##   * one-shots  — play(): fire-and-forget stingers (the console popup, the
##     ship-arrival sound). A small pool of voices means two that overlap don't
##     cut each other off.
##   * footsteps  — a single looping player. The level in play decides *which*
##     walking sound to use (set_footsteps_stream); the walker toggles it on and
##     off (set_walking) as it starts and stops moving, so the loop stops the
##     instant the player stands still.
##
## Everything plays on the Master bus, so the settings menu's master volume
## already controls it.

# --- Sound library -------------------------------------------------
const MOUSE_CLICK: AudioStream = preload("res://Assets/Music/SFX/Mouse_Click.mp3")
const CONSOLE_POPUP: AudioStream = preload("res://Assets/Music/SFX/Console_Popup.mp3")
const SHIP_ENTER: AudioStream = preload("res://Assets/Music/SFX/Ship_Scene_Enter.mp3")
const WALK_BASE_CAMP: AudioStream = preload("res://Assets/Music/SFX/Walking_Base_Camp_Scene.mp3")
const WALK_SHIP: AudioStream = preload("res://Assets/Music/SFX/Walking_Ship_Scene.mp3")

## How many one-shots can sound at once before the oldest voice is reused.
const ONESHOT_VOICES: int = 8

var _oneshot_players: Array[AudioStreamPlayer] = []
var _next_oneshot: int = 0

var _footsteps: AudioStreamPlayer
## The walking sound for the current scene, or null in scenes that have none.
var _footsteps_stream: AudioStream = null


func _ready() -> void:
	for _i in ONESHOT_VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_oneshot_players.append(player)

	_footsteps = AudioStreamPlayer.new()
	add_child(_footsteps)


## A click sound on every mouse press, anywhere — gameplay or UI alike, since
## this autoload sees input before the scene does. Only the down-press of the
## left or right button counts; releases and the mouse wheel don't.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			play(MOUSE_CLICK)


## Fire a one-shot. Cheap to spam: rotates through the voice pool so a new sound
## never cuts the previous one short.
func play(stream: AudioStream) -> void:
	if stream == null:
		return
	var player := _oneshot_players[_next_oneshot]
	_next_oneshot = (_next_oneshot + 1) % _oneshot_players.size()
	player.stream = stream
	player.play()


## Picks which walking sound the footsteps loop uses. Levels call this in _ready;
## passing null (what the walker does on the way out) stops and clears it, so a
## scene that never sets a walking sound simply has none.
func set_footsteps_stream(stream: AudioStream) -> void:
	if stream == _footsteps_stream:
		return
	stop_footsteps()
	_footsteps_stream = stream
	# An mp3 only repeats when its own stream says so; footsteps must loop, or the
	# sound would die after one pass while the player is still walking. These
	# streams are used for nothing but footsteps, so marking them loop is safe.
	if stream is AudioStreamMP3:
		stream.loop = true


## Starts or stops the footsteps loop. No-op when the current scene set no
## walking sound. Called by the player every time it starts or stops moving.
func set_walking(walking: bool) -> void:
	if not walking:
		stop_footsteps()
		return
	if _footsteps_stream == null or _footsteps.playing:
		return
	_footsteps.stream = _footsteps_stream
	_footsteps.play()


func stop_footsteps() -> void:
	if _footsteps != null and _footsteps.playing:
		_footsteps.stop()
