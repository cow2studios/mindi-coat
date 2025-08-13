# scripts/GameManager.gd attached to Main.tcsn
extends Node2D

const CardScene = preload("res://scenes/Card.tscn")

@onready var player_hand_pos = $PlayerHandPos

# This line has been corrected to remove the nested type.
var players_hands: Array = [[], [], [], []] # Player 0 is human

func _ready():
	start_new_game()

func start_new_game():
	# 1. Get a shuffled deck from our global Deck node
	var deck = Deck.get_shuffled_deck()
	
	# 2. Deal 13 cards to each of the 4 players' data arrays
	for i in range(13):
		for player_index in range(4):
			players_hands[player_index].append(deck.pop_front())
	
	# 3. Display the human player's hand visually
	display_player_hand()

func display_player_hand():
	var hand = players_hands[0]
	var card_spacing = 40 # Pixels between cards
	var total_width = (hand.size() - 1) * card_spacing
	var start_x = player_hand_pos.position.x - total_width / 2

	for i in range(hand.size()):
		var card_data = hand[i]
		var card_instance = CardScene.instantiate()
		add_child(card_instance)
		card_instance.position.x = start_x + (i * card_spacing)
		card_instance.position.y = player_hand_pos.position.y
		card_instance.display_card(card_data)
		# Connect the signal from this specific card instance to our manager
		card_instance.card_clicked.connect(_on_card_clicked)

func _on_card_clicked(card_data: CardData):
	print("Player clicked: %s of %s" % [CardData.Rank.keys()[card_data.rank], CardData.Suit.keys()[card_data.suit]])