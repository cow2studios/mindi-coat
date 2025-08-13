# scripts/CardResourceGenerator.gd attached to cardResourceGenerator
# This script generates card resources .tres files from the source images.
@tool
extends Node

@export var generate_cards: bool = false:
	set(value):
		if value:
			_generate_card_resources()

const SOURCE_IMAGE_PATH = "res://assets/cards/"
const OUTPUT_RESOURCE_PATH = "res://assets/card_data/"

func _generate_card_resources():
	print("Starting card resource generation...")
	DirAccess.make_dir_recursive_absolute(OUTPUT_RESOURCE_PATH)
	var dir = DirAccess.open(SOURCE_IMAGE_PATH)
	if not dir:
		print("ERROR: Could not open source image directory at: ", SOURCE_IMAGE_PATH)
		return

	for file_name in dir.get_files():
		if not file_name.ends_with(".png") or file_name == "card_back.png":
			continue

		var parts = file_name.trim_suffix(".png").split("_")
		if parts.size() != 3:
			print("WARNING: Skipping malformed file: ", file_name)
			continue
			
		var suit_str = parts[1]
		var rank_str = parts[2]
		var card = CardData.new()
		
		match suit_str:
			"clubs": card.suit = CardData.Suit.CLUBS
			"diamonds": card.suit = CardData.Suit.DIAMONDS
			"hearts": card.suit = CardData.Suit.HEARTS
			"spades": card.suit = CardData.Suit.SPADES
		
		match rank_str:
			"02": card.rank = CardData.Rank._02; card.value = 2
			"03": card.rank = CardData.Rank._03; card.value = 3
			"04": card.rank = CardData.Rank._04; card.value = 4
			"05": card.rank = CardData.Rank._05; card.value = 5
			"06": card.rank = CardData.Rank._06; card.value = 6
			"07": card.rank = CardData.Rank._07; card.value = 7
			"08": card.rank = CardData.Rank._08; card.value = 8
			"09": card.rank = CardData.Rank._09; card.value = 9
			"10": card.rank = CardData.Rank._10; card.value = 10
			"J": card.rank = CardData.Rank.J; card.value = 11
			"Q": card.rank = CardData.Rank.Q; card.value = 12
			"K": card.rank = CardData.Rank.K; card.value = 13
			"A": card.rank = CardData.Rank.A; card.value = 14

		card.texture = load(SOURCE_IMAGE_PATH + file_name)
		var save_path = "%scard_%s_%s.tres" % [OUTPUT_RESOURCE_PATH, suit_str, rank_str]
		ResourceSaver.save(card, save_path)

	print("SUCCESS: Card resource generation complete!")