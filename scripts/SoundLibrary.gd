# scripts/SoundLibrary.gd
extends Resource
class_name SoundLibrary

# This will store all our sounds, like {"card-place-1": AudioStream, ...}
@export var sfx: Dictionary = {}