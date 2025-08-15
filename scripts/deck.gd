# Loads the master deck list and provides shuffled decks.
extends Node

const DeckListResource = preload("res://assets/deck_list.tres")

func _ready():
	print("Deck loaded with %s cards." % DeckListResource.cards.size())

func get_shuffled_deck() -> Array[CardData]:
	var new_deck = DeckListResource.cards.duplicate()
	new_deck.shuffle()
	return new_deck