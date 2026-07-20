extends Node

## Background music: the three BGM tracks on shuffle, forever.
##
## Autoloaded, so the music plays straight through scene changes — a song is
## never cut off in the middle just because the player walked into another room.
## Deliberately quiet: it sits *under* the sound effects, not over them.

const TRACKS: Array[AudioStream] = [
	preload("res://Assets/Music/BGM/BGM_1.mp3"),
	preload("res://Assets/Music/BGM/BGM_2.mp3"),
	preload("res://Assets/Music/BGM/BGM_3.mp3"),
]

## How loud the music sits, in decibels below the file's own level. Background
## music, so it's kept low on purpose — lower this further for quieter, raise it
## towards 0 for louder.
const VOLUME_DB: float = -18.0

var _player: AudioStreamPlayer

## The tracks still to play before the bag is refilled and reshuffled. A shuffle
## bag plays every song once before any repeats — that reads as "random order"
## far better than true random, which happily plays the same track three times
## in a row.
var _bag: Array[AudioStream] = []


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = VOLUME_DB
	# The moment one song ends, roll into the next.
	_player.finished.connect(_play_next)
	add_child(_player)

	# A track set to loop would play forever and never fire `finished`, so the
	# shuffle would stall on song one. These are meant to hand off, not loop.
	for track in TRACKS:
		if track is AudioStreamMP3:
			track.loop = false

	_play_next()


func _play_next() -> void:
	if _bag.is_empty():
		_refill_bag()
	_player.stream = _bag.pop_back()
	_player.play()


## Refills and reshuffles the bag, keeping the just-played track off the end so
## the seam between two bags never repeats a song back-to-back.
func _refill_bag() -> void:
	_bag = TRACKS.duplicate()
	_bag.shuffle()
	# pop_back() takes from the end, so the last element is what plays next. If
	# that's the song we just finished, swap it to the front instead.
	if _player.stream != null and _bag.size() > 1 and _bag.back() == _player.stream:
		_bag[_bag.size() - 1] = _bag[0]
		_bag[0] = _player.stream
