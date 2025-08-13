# scripts/deck.gd attached to deck.tcsn
extends Node2D

var card_resources: Array[CardData] = []

func _ready():
	var data_path = "res://assets/card_data/"
	var dir = DirAccess.open(data_path)
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".tres"):
				card_resources.append(load(data_path + file_name))
	print("Deck loaded with %s cards." % card_resources.size())

func get_shuffled_deck() -> Array[CardData]:
	var new_deck = card_resources.duplicate()
	new_deck.shuffle()
	return new_deck