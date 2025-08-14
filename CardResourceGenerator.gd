# scripts/CardResourceGenerator.gd (NEW VERSION)
@tool
extends Node2D

@export var generate_deck_resource: bool = false:
	set(value):
		if value:
			_generate_deck_list()

const SOURCE_CARD_DATA_PATH = "res://assets/card_data/"
const OUTPUT_PATH = "res://assets/"

func _generate_deck_list():
	var dir = DirAccess.open(SOURCE_CARD_DATA_PATH)
	if not dir:
		print("ERROR: Card data directory not found.")
		return
	
	var deck_list = DeckList.new()
	
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var card_data = load(SOURCE_CARD_DATA_PATH + file_name)
			deck_list.cards.append(card_data)
	
	if deck_list.cards.size() == 52:
		var save_path = OUTPUT_PATH + "deck_list.tres"
		ResourceSaver.save(deck_list, save_path)
		print("SUCCESS: Master deck_list.tres created with 52 cards at ", save_path)
	else:
		print("ERROR: Found %s cards instead of 52. Aborting." % deck_list.cards.size())