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
var players_hands: Array = [] # Initialize as an empty array
var cards_on_table: Array[CardData] = []
var player_who_played: Array[int] = []
var current_turn_index = 0
var trick_leader_index = 0
var hukum_suit: CardData.Suit
var is_hukum_set = false
var team_tricks_captured: Array = [[], []]

func _ready():
	timer.timeout.connect(on_timer_timeout)
	start_new_game()

func start_new_game():
	# --- Reset game variables ---
	## NEW AND CORRECTED INITIALIZATION ##
	players_hands.clear()
	for i in range(4):
		var typed_hand: Array[CardData] = [] # Create a specifically typed array
		players_hands.append(typed_hand) # Add the typed array to our list of hands

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
		timer.start(1.5)
	else:
		next_turn()

func _on_card_clicked(card_data: CardData):
	if current_state != GameState.PLAYER_TURN: return
	
	var legal_moves = get_legal_moves(0)
	
	if card_data in legal_moves:
		play_card(card_data, 0)
	else:
		print("Illegal move! You must follow the lead suit.")

func get_legal_moves(player_index: int) -> Array[CardData]:
	# This function is now correct because players_hands[player_index] is a typed array
	var hand: Array[CardData] = players_hands[player_index]
	
	if cards_on_table.is_empty():
		return hand
	
	var lead_suit = cards_on_table[0].suit
	var moves_in_suit: Array[CardData] = []
	
	for card in hand:
		if card.suit == lead_suit:
			moves_in_suit.append(card)
	
	if not moves_in_suit.is_empty():
		return moves_in_suit
	else:
		return hand

func evaluate_trick():
	var winning_card = cards_on_table[0]
	var winner_index_in_trick = 0
	var lead_suit = winning_card.suit
	
	for i in range(1, cards_on_table.size()):
		var current_card = cards_on_table[i]
		
		if is_hukum_set and current_card.suit == hukum_suit and winning_card.suit != hukum_suit:
			winning_card = current_card
			winner_index_in_trick = i
		elif is_hukum_set and current_card.suit == hukum_suit and winning_card.suit == hukum_suit:
			if current_card.value > winning_card.value:
				winning_card = current_card
				winner_index_in_trick = i
		elif current_card.suit == lead_suit and winning_card.suit == lead_suit:
			if current_card.value > winning_card.value:
				winning_card = current_card
				winner_index_in_trick = i
	
	self.trick_leader_index = player_who_played[winner_index_in_trick]
	var winner_team = trick_leader_index % 2
	
	team_tricks_captured[winner_team].append_array(cards_on_table)
	
	print("Trick won by Player %s with the %s of %s" % [trick_leader_index, CardData.Rank.keys()[winning_card.rank], CardData.Suit.keys()[winning_card.suit]])
	
	cards_on_table.clear()
	player_who_played.clear()
	for node in get_tree().get_nodes_in_group("table_cards"):
		node.queue_free()
	
	if players_hands[0].is_empty():
		print("--- GAME OVER ---")
		current_state = GameState.WAITING
	else:
		start_next_trick()

func next_turn():
	current_turn_index = (current_turn_index + 1) % 4
	set_turn_state()

func start_next_trick():
	print("--- New trick started by Player %s ---" % trick_leader_index)
	current_turn_index = trick_leader_index
	set_turn_state()

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
		timer.start(0.75)

func do_ai_turn():
	if current_state != GameState.AI_TURN: return
	
	var legal_moves = get_legal_moves(current_turn_index)
	
	if not legal_moves.is_empty():
		var card_to_play = legal_moves[0]
		play_card(card_to_play, current_turn_index)
	else:
		print("ERROR: AI has no legal moves, this shouldn't happen.")

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
