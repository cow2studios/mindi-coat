# scripts/GameManager.gd attached to Main.tcsn
extends Node2D

const CardScene = preload("res://scenes/Card.tscn")

# -- Node References --
@onready var player_hand_pos = $PlayerHandPos
@onready var play_area_pos = $PlayAreaPos
@onready var timer = $Timer

# -- Game State --
enum GameState {PLAYER_TURN, AI_TURN, EVALUATING, WAITING}
var current_state = GameState.WAITING

# -- Game Logic Variables --
var players_hands: Array = [[], [], [], []]
var cards_on_table: Array[CardData] = []
var player_who_played: Array[int] = [] # Track who played which card
var current_turn_index = 0
var trick_leader_index = 0
var hukum_suit: CardData.Suit
var is_hukum_set = false
var team_tricks_captured: Array = [[], []] # Team 0 (Player/Partner), Team 1 (Opponents)

func _ready():
	timer.timeout.connect(on_timer_timeout)
	start_new_game()

func start_new_game():
	# --- Reset game variables ---
	players_hands = [[], [], [], []]
	cards_on_table.clear()
	player_who_played.clear()
	is_hukum_set = false
	team_tricks_captured = [[], []]
	for node in get_tree().get_nodes_in_group("cards"):
		node.queue_free()

	# --- Deal cards ---
	var deck = Deck.get_shuffled_deck()
	for i in range(13):
		for player_index in range(4):
			players_hands[player_index].append(deck.pop_front())
	
	display_player_hand()
	
	# --- Start the game ---
	trick_leader_index = 0
	start_next_trick()

func play_card(card_data: CardData, player_index: int):
	players_hands[player_index].erase(card_data)
	cards_on_table.append(card_data)
	player_who_played.append(player_index)
	
	# --- NEW: Logic to set the Hukum (Trump) ---
	if not is_hukum_set and cards_on_table.size() > 1:
		var lead_suit = cards_on_table[0].suit
		if card_data.suit != lead_suit:
			is_hukum_set = true
			hukum_suit = card_data.suit
			print("--- HUKUM SET TO: %s ---" % CardData.Suit.keys()[hukum_suit])
	
	display_card_on_table(card_data, player_index)
	
	if player_index == 0:
		display_player_hand()
	
	if cards_on_table.size() == 4:
		current_state = GameState.EVALUATING
		# Wait a moment before evaluating so the player can see the last card
		timer.start(1.5)
	else:
		next_turn()

func _on_card_clicked(card_data: CardData):
	if current_state != GameState.PLAYER_TURN: return
	play_card(card_data, 0)

# --- NEW: The core game logic function ---
func evaluate_trick():
	var winning_card = cards_on_table[0]
	var winner_index_in_trick = 0 # This is the index within the trick (0-3)
	var lead_suit = winning_card.suit
	
	# Loop through the other 3 cards on the table
	for i in range(1, cards_on_table.size()):
		var current_card = cards_on_table[i]
		
		# Condition 1: Current card is hukum, but winner is not. Current card wins.
		if is_hukum_set and current_card.suit == hukum_suit and winning_card.suit != hukum_suit:
			winning_card = current_card
			winner_index_in_trick = i
		# Condition 2: Both are hukum. Highest value wins.
		elif is_hukum_set and current_card.suit == hukum_suit and winning_card.suit == hukum_suit:
			if current_card.value > winning_card.value:
				winning_card = current_card
				winner_index_in_trick = i
		# Condition 3: Neither are hukum, but both are lead suit. Highest value wins.
		elif current_card.suit == lead_suit and winning_card.suit == lead_suit:
			if current_card.value > winning_card.value:
				winning_card = current_card
				winner_index_in_trick = i
	
	# Get the actual player index of the winner (0-3)
	self.trick_leader_index = player_who_played[winner_index_in_trick]
	var winner_team = trick_leader_index % 2 # 0 or 2 -> Team 0. 1 or 3 -> Team 1.
	
	# Add the captured cards to the winner's team pile
	team_tricks_captured[winner_team].append_array(cards_on_table)
	
	print("Trick won by Player %s with the %s of %s" % [trick_leader_index, CardData.Rank.keys()[winning_card.rank], CardData.Suit.keys()[winning_card.suit]])
	
	# Clean up for the next trick
	cards_on_table.clear()
	player_who_played.clear()
	for node in get_tree().get_nodes_in_group("table_cards"):
		node.queue_free()
	
	# Check if the game is over
	if players_hands[0].is_empty():
		print("--- GAME OVER ---")
		current_state = GameState.WAITING
		# We will add final scoring later
	else:
		start_next_trick()

func next_turn():
	current_turn_index = (current_turn_index + 1) % 4
	set_turn_state()

# --- NEW: A dedicated function to start a new trick ---
func start_next_trick():
	print("--- New trick started by Player %s ---" % trick_leader_index)
	current_turn_index = trick_leader_index
	set_turn_state()

# --- NEW: Handles what to do when the timer finishes ---
func on_timer_timeout():
	if current_state == GameState.AI_TURN:
		do_ai_turn()
	elif current_state == GameState.EVALUATING:
		evaluate_trick()

func set_turn_state():
	if current_turn_index == 0:
		current_state = GameState.PLAYER_TURN
	else:
		current_state = GameState.AI_TURN
		timer.start(0.75) # AI's "thinking" time

func do_ai_turn():
	if current_state != GameState.AI_TURN: return # Safety check
	
	var ai_hand = players_hands[current_turn_index]
	# Simple AI: just play the first card
	var card_to_play = ai_hand[0]
	play_card(card_to_play, current_turn_index)

# (The display_player_hand and display_card_on_table functions remain the same)
func display_player_hand():
	for node in get_tree().get_nodes_in_group("player_hand_cards"):
		node.queue_free()
	var hand = players_hands[0]
	var card_spacing = 40
	var total_width = (hand.size() - 1) * card_spacing
	var start_x = player_hand_pos.position.x - total_width / 2
	for i in range(hand.size()):
		var card_data = hand[i]
		var card_instance = CardScene.instantiate()
		add_child(card_instance)
		card_instance.position.x = start_x + (i * card_spacing)
		card_instance.position.y = player_hand_pos.position.y
		card_instance.display_card(card_data)
		card_instance.card_clicked.connect(_on_card_clicked)
		card_instance.add_to_group("player_hand_cards")
		card_instance.add_to_group("cards")

func display_card_on_table(card_data: CardData, player_index: int):
	var card_instance = CardScene.instantiate()
	add_child(card_instance)
	var offset = Vector2.ZERO
	match player_index:
		0: offset = Vector2(0, 50)
		1: offset = Vector2(50, 0)
		2: offset = Vector2(0, -50)
		3: offset = Vector2(-50, 0)
	card_instance.position = play_area_pos.position + offset
	card_instance.display_card(card_data)
	card_instance.add_to_group("table_cards")
	card_instance.add_to_group("cards")