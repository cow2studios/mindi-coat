# scripts/SoundGenerator.gd
@tool
extends Node

@export var generate_sound_library: bool = false:
	set(value):
		if value:
			_generate_library()

const FOLDERS_TO_SCAN = [
	"res://assets/audio/",
	"res://assets/ui/sounds/"
]
const OUTPUT_PATH = "res://assets/sound_library.tres"

func _generate_library():
	var library = SoundLibrary.new()
	
	for folder_path in FOLDERS_TO_SCAN:
		var dir = DirAccess.open(folder_path)
		if not dir:
			print("SoundGenerator ERROR: Directory not found - ", folder_path)
			continue
		
		for file_name in dir.get_files():
			if file_name.ends_with(".ogg"):
				var sound_name = file_name.trim_suffix(".ogg")
				library.sfx[sound_name] = load(folder_path + file_name)
	
	ResourceSaver.save(library, OUTPUT_PATH)
	print("SUCCESS: Master sound_library.tres created with %s sounds." % library.sfx.size())