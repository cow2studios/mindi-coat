# scripts/SoundManager.gd
extends Node

const NUM_PLAYERS = 8 # The number of sounds that can play at once

var sfx_library = {}
var players = []
var rng = RandomNumberGenerator.new()

func _ready():
	# Create a pool of audio players
	for i in range(NUM_PLAYERS):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	
	# Load sounds from all necessary directories
	_load_sfx_from_dir("res://assets/audio/")
	_load_sfx_from_dir("res://assets/ui/sounds/")
	
	print("SoundManager loaded %s sound effects." % sfx_library.size())

# NEW: Helper function to load sounds from a specific path
func _load_sfx_from_dir(path):
	var dir = DirAccess.open(path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".ogg"):
				var sound_name = file_name.trim_suffix(".ogg")
				if sfx_library.has(sound_name):
					print("SoundManager Warning: Duplicate sound name found - ", sound_name)
				sfx_library[sound_name] = load(path + file_name)
	else:
		print("SoundManager Error: Directory not found - ", path)

# This is the main function we'll call from other scripts
func play(sound_name):
	# First, find all sounds that start with this name
	var sound_variations = []
	for key in sfx_library:
		if key.begins_with(sound_name):
			sound_variations.append(sfx_library[key])

	if sound_variations.is_empty():
		print("SoundManager Error: Sound not found - ", sound_name)
		return

	# Pick a random sound from the variations
	var random_sound = sound_variations[rng.randi_range(0, sound_variations.size() - 1)]

	# Find an available audio player and play the sound
	for player in players:
		if not player.playing:
			player.stream = random_sound
			player.play()
			return