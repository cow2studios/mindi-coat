# scripts/SoundManager.gd (NEW, SIMPLER VERSION)
extends Node

const NUM_PLAYERS = 8 # The number of sounds that can play at once

# Preload the master sound library resource
const SoundLibraryResource = preload("res://assets/sound_library.tres")

var players = []
var rng = RandomNumberGenerator.new()

func _ready():
	# Create a pool of audio players
	for i in range(NUM_PLAYERS):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	
	print("SoundManager ready. Loaded %s sounds from library." % SoundLibraryResource.sfx.size())

func play(sound_name):
	var sound_variations = []
	# Find variations in our preloaded library
	for key in SoundLibraryResource.sfx:
		if key.begins_with(sound_name):
			sound_variations.append(SoundLibraryResource.sfx[key])

	if sound_variations.is_empty():
		print("SoundManager Error: Sound not found - ", sound_name)
		return

	var random_sound = sound_variations[rng.randi_range(0, sound_variations.size() - 1)]

	for player in players:
		if not player.playing:
			player.stream = random_sound
			player.play()
			return