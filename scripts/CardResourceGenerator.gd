# scripts/CardResourceGenerator.gd (All-in-One Version)
@tool
extends Node

@export var generate_all_card_resources: bool = false:
	set(value):
		if value:
			_generate_all()

const SOURCE_IMAGE_PATH = "res://assets/cards/"
const CARD_DATA_OUTPUT_PATH = "res://assets/card_data/"
const DECK_LIST_OUTPUT_PATH = "res://assets/deck_list.tres"

func _generate_all():
	# Step 1: Create the 52 individual .tres files from the new .png names
	print("Step 1: Generating 52 individual card resources...")
	DirAccess.make_dir_recursive_absolute(CARD_DATA_OUTPUT_PATH)
	var image_dir = DirAccess.open(SOURCE_IMAGE_PATH)
	if not image_dir:
		print("ERROR: Image source directory not found.")
		return

	for file_name in image_dir.get_files():
		if not file_name.ends_with(".png") or file_name.begins_with("back") or file_name.begins_with("Joker"):
			continue

		var parts = file_name.trim_suffix(".png").split("_")
		if parts.size() != 2:
			print("WARNING: Skipping malformed file: ", file_name)
			continue
		
		var suit_str = parts[0]
		var rank_str = parts[1]
		var card = CardData.new()
		
		# Set Suit
		match suit_str:
			"clubs": card.suit = CardData.Suit.CLUBS
			"diamonds": card.suit = CardData.Suit.DIAMONDS
			"hearts": card.suit = CardData.Suit.HEARTS
			"spades": card.suit = CardData.Suit.SPADES
		
		# Set Rank and Value from new names
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
			"jack": card.rank = CardData.Rank.J; card.value = 11
			"queen": card.rank = CardData.Rank.Q; card.value = 12
			"king": card.rank = CardData.Rank.K; card.value = 13
			"ace": card.rank = CardData.Rank.A; card.value = 14

		card.texture = load(SOURCE_IMAGE_PATH + file_name)
		var save_path = "%scard_%s_%s.tres" % [CARD_DATA_OUTPUT_PATH, suit_str, rank_str]
		ResourceSaver.save(card, save_path)

	print("Step 1 SUCCESS: Individual card resources created.")

	# Step 2: Create the master deck_list.tres from the files we just made
	print("Step 2: Generating master deck_list.tres...")
	var data_dir = DirAccess.open(CARD_DATA_OUTPUT_PATH)
	if not data_dir:
		print("ERROR: Card data directory not found for Step 2.")
		return
	
	var deck_list = DeckList.new()
	for file_name in data_dir.get_files():
		if file_name.ends_with(".tres"):
			deck_list.cards.append(load(CARD_DATA_OUTPUT_PATH + file_name))
	
	if deck_list.cards.size() == 52:
		ResourceSaver.save(deck_list, DECK_LIST_OUTPUT_PATH)
		print("Step 2 SUCCESS: Master deck_list.tres created with 52 cards.")
	else:
		print("ERROR: Found %s cards instead of 52. Aborting." % deck_list.cards.size())