# scripts/GameManager.gd attached to Main
extends Node2D

## SIGNALS ##
signal score_updated(team_scores)
signal hukum_updated(suit_name)
signal game_over(message)
signal lead_suit_updated(suit_name)

const CardScene = preload("res://scenes/Card.tscn")

# -- Node References --
@onready var player_hand_pos = $PlayerHandPos
@onready var play_area_pos = $PlayAreaPos
@onready var timer = $Timer
@onready var hud = $HUD

# -- Game State --
enum GameState {PLAYER_TURN, AI_TURN, EVALUATING, WAITING}
var current_state = GameState.WAITING

# -- Game Logic Variables --
var players_hands: Array = []
var cards_on_table: Array[CardData] = []
var player_who_played: Array[int] = []
var current_turn_index = 0
var trick_leader_index = 0
var hukum_suit: CardData.Suit
var is_hukum_set = false
var team_tricks_captured: Array = [[], []]
var team_mindi_count = [0, 0]

func _ready():
	timer.timeout.connect(on_timer_timeout)
	
	score_updated.connect(hud.update_score)
	hukum_updated.connect(hud.update_hukum)
	game_over.connect(hud.show_game_over)
	lead_suit_updated.connect(hud.update_lead_suit)

	start_new_game()

func start_new_game():
	# --- Reset game variables ---
	players_hands.clear()
	for i in range(4):
		var typed_hand: Array[CardData] = []
		players_hands.append(typed_hand)

	cards_on_table.clear()
	player_who_played.clear()
	is_hukum_set = false
	team_tricks_captured = [[], []]
	team_mindi_count = [0, 0]
	
	# --- Reset the HUD for a new game ---
	hud.game_over_panel.hide()
	emit_signal("score_updated", team_mindi_count)
	emit_signal("hukum_updated", "None")
	emit_signal("lead_suit_updated", "None") ## NEW: Reset lead suit display ##
	
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
	
	## NEW: Emit the lead suit when the first card is played ##
	if cards_on_table.size() == 1:
		emit_signal("lead_suit_updated", CardData.Suit.keys()[card_data.suit])
	
	if not is_hukum_set and cards_on_table.size() > 1:
		var lead_suit = cards_on_table[0].suit
		if card_data.suit != lead_suit:
			is_hukum_set = true
			hukum_suit = card_data.suit
			var suit_name = CardData.Suit.keys()[hukum_suit]
			print("--- HUKUM SET TO: %s ---" % suit_name)
			emit_signal("hukum_updated", suit_name)
	
	display_card_on_table(card_data, player_index)
	
	if player_index == 0:
		display_player_hand()
	
	if cards_on_table.size() == 4:
		current_state = GameState.EVALUATING
		timer.start(1.5)
	else:
		next_turn()

func evaluate_trick():
	var winning_card = cards_on_table[0]
	var winner_index_in_trick = 0
	var lead_suit = winning_card.suit
	
	for i in range(1, cards_on_table.size()):
		var current_card = cards_on_table[i]
		
		if is_hukum_set and current_card.suit == hukum_suit and winning_card.suit != hukum_suit:
			winning_card = current_card; winner_index_in_trick = i
		elif is_hukum_set and current_card.suit == hukum_suit and winning_card.suit == hukum_suit:
			if current_card.value > winning_card.value: winning_card = current_card; winner_index_in_trick = i
		elif current_card.suit == lead_suit and winning_card.suit == lead_suit:
			if current_card.value > winning_card.value: winning_card = current_card; winner_index_in_trick = i
	
	self.trick_leader_index = player_who_played[winner_index_in_trick]
	var winner_team = trick_leader_index % 2
	
	for card in cards_on_table:
		if card.rank == CardData.Rank._10:
			team_mindi_count[winner_team] += 1
	emit_signal("score_updated", team_mindi_count)
	
	team_tricks_captured[winner_team].append_array(cards_on_table)
	print("Trick won by Player %s" % trick_leader_index)
	emit_signal("lead_suit_updated", "None") ## NEW: Clear the lead suit display ##
	
	cards_on_table.clear()
	player_who_played.clear()
	for node in get_tree().get_nodes_in_group("table_cards"):
		node.queue_free()
	
	if players_hands[0].is_empty():
		print("DEBUG: Hand is empty! Calling end_round().")
		end_round()
	else:
		start_next_trick()

func end_round():
	current_state = GameState.WAITING
	var final_message = ""
	if team_mindi_count[0] > team_mindi_count[1]:
		final_message = "Your Team Wins!\nScore: %s - %s" % [team_mindi_count[0], team_mindi_count[1]]
		if team_mindi_count[1] == 0: final_message += "\nCOAT!"
	elif team_mindi_count[1] > team_mindi_count[0]:
		final_message = "Opponents Win!\nScore: %s - %s" % [team_mindi_count[0], team_mindi_count[1]]
		if team_mindi_count[0] == 0: final_message += "\nCOAT!"
	else:
		final_message = "It's a Draw!\nScore: 2 - 2"
	
	emit_signal("game_over", final_message)

func _on_card_clicked(card_data: CardData):
	if current_state != GameState.PLAYER_TURN: return
	var legal_moves = get_legal_moves(0)
	if card_data in legal_moves: play_card(card_data, 0)
	else: print("Illegal move! You must follow the lead suit.")

func get_legal_moves(player_index: int) -> Array[CardData]:
	var hand: Array[CardData] = players_hands[player_index]
	if cards_on_table.is_empty(): return hand
	var lead_suit = cards_on_table[0].suit
	var moves_in_suit: Array[CardData] = []
	for card in hand:
		if card.suit == lead_suit: moves_in_suit.append(card)
	if not moves_in_suit.is_empty(): return moves_in_suit
	else: return hand

func next_turn():
	current_turn_index = (current_turn_index + 1) % 4
	set_turn_state()

func start_next_trick():
	print("--- New trick started by Player %s ---" % trick_leader_index)
	current_turn_index = trick_leader_index
	set_turn_state()

func on_timer_timeout():
	if current_state == GameState.AI_TURN: do_ai_turn()
	elif current_state == GameState.EVALUATING: evaluate_trick()

func set_turn_state():
	if current_turn_index == 0: current_state = GameState.PLAYER_TURN
	else:
		current_state = GameState.AI_TURN
		timer.start(0.75)

## UPDATED do_ai_turn FUNCTION ##
func do_ai_turn():
	if current_state != GameState.AI_TURN: return
	
	var legal_moves = get_legal_moves(current_turn_index)
	
	if not legal_moves.is_empty():
		# Instead of playing the first card, choose the BEST card
		var card_to_play = choose_best_card(current_turn_index, legal_moves)
		play_card(card_to_play, current_turn_index)
	else: print("ERROR: AI has no legal moves, this shouldn't happen.")

func display_player_hand():
	for node in get_tree().get_nodes_in_group("player_hand_cards"): node.queue_free()
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

## HELPER FUNCTION for AI ##
# Gets the current state of the trick, now including win strength
func get_trick_context():
	var context = {
		"winning_card": null,
		"winning_player": - 1,
		"has_mindi": false,
		"is_strong_win": false ## NEW: Is the win almost guaranteed?
	}
	if cards_on_table.is_empty():
		return context

	# --- (The existing logic to find the winner is the same) ---
	context.winning_card = cards_on_table[0]
	context.winning_player = player_who_played[0]
	var lead_suit = context.winning_card.suit
	for i in range(1, cards_on_table.size()):
		var current_card = cards_on_table[i]
		var is_current_winner_hukum = is_hukum_set and context.winning_card.suit == hukum_suit
		var is_this_card_hukum = is_hukum_set and current_card.suit == hukum_suit
		
		if is_this_card_hukum and not is_current_winner_hukum:
			context.winning_card = current_card; context.winning_player = player_who_played[i]
		elif is_this_card_hukum and is_current_winner_hukum:
			if current_card.value > context.winning_card.value: context.winning_card = current_card; context.winning_player = player_who_played[i]
		elif not is_this_card_hukum and not is_current_winner_hukum and current_card.suit == lead_suit:
			if current_card.value > context.winning_card.value: context.winning_card = current_card; context.winning_player = player_who_played[i]

	# --- (Check for Mindi is the same) ---
	for card in cards_on_table:
		if card.rank == CardData.Rank._10:
			context.has_mindi = true
			break
	
	## NEW: Determine if the win is "strong" ##
	if is_hukum_set and context.winning_card.suit == hukum_suit:
		context.is_strong_win = true # Any hukum is a strong win
	elif context.winning_card.value >= 13: # Ace or King
		context.is_strong_win = true
			
	return context

## FINAL UPDATED AI BRAIN FUNCTION ##
func choose_best_card(player_index: int, legal_moves: Array[CardData]) -> CardData:
	legal_moves.sort_custom(func(a, b): return a.value < b.value)
	var lowest_card = legal_moves[0]

	# SCENARIO A: AI is leading the trick (No change here)
	if cards_on_table.is_empty():
		var high_cards = legal_moves.filter(func(card): return card.value >= 13 and (not is_hukum_set or card.suit != hukum_suit))
		if not high_cards.is_empty():
			return high_cards[-1]
		return lowest_card

	# SCENARIO B: AI is following
	var context = get_trick_context()
	var partner_is_winning = context.winning_player % 2 == player_index % 2

	# If partner is winning, check for assist opportunity
	if partner_is_winning:
		var lead_suit = cards_on_table[0].suit
		var can_follow_suit = lowest_card.suit == lead_suit

		## NEW PARTNER LOGIC ##
		if can_follow_suit and context.is_strong_win:
			# Check if we have a Mindi of this suit to give to our partner
			for card in legal_moves:
				if card.rank == CardData.Rank._10:
					print("AI Player %s is assisting partner by playing a Mindi!" % player_index)
					return card # Play the Mindi for profit!
		
		# If no assist is possible, play safe
		if not can_follow_suit:
			var full_hand = players_hands[player_index]
			full_hand.sort_custom(func(a, b): return a.value < b.value)
			for card in full_hand:
				if is_hukum_set and card.suit != hukum_suit: return card
			return full_hand[0]
		return lowest_card # Play lowest card of the suit to not risk taking the trick
	
	# If an opponent is winning (No change to this logic)
	else:
		var lead_suit = cards_on_table[0].suit
		var can_follow_suit = lowest_card.suit == lead_suit
		if can_follow_suit:
			var cards_that_can_win = legal_moves.filter(func(card): return card.value > context.winning_card.value)
			if not cards_that_can_win.is_empty(): return cards_that_can_win[0]
			else: return lowest_card
		else:
			if not is_hukum_set:
				var best_suit_to_set = choose_best_hukum_suit(players_hands[player_index], lead_suit)
				for card in legal_moves:
					if card.suit == best_suit_to_set: return card
			var hukum_cards = legal_moves.filter(func(card): return card.suit == hukum_suit)
			if not hukum_cards.is_empty():
				if context.has_mindi or (context.winning_card.suit == hukum_suit and context.winning_card.value > 10):
					return hukum_cards[0]
		return lowest_card

## NEW FUNCTION: Determines the best suit to declare as hukum ##
func choose_best_hukum_suit(hand: Array[CardData], lead_suit: CardData.Suit) -> CardData.Suit:
	var suit_scores = {
		CardData.Suit.SPADES: 0,
		CardData.Suit.HEARTS: 0,
		CardData.Suit.DIAMONDS: 0,
		CardData.Suit.CLUBS: 0,
	}

	# Remove the lead suit from consideration
	suit_scores.erase(lead_suit)

	# Score each remaining suit
	for card in hand:
		if card.suit == lead_suit:
			continue # Skip cards of the lead suit

		# Base score for having a card of that suit
		suit_scores[card.suit] += 1
		# Add bonus points for high cards
		match card.rank:
			CardData.Rank.A: suit_scores[card.suit] += 5
			CardData.Rank.K: suit_scores[card.suit] += 4
			CardData.Rank.Q: suit_scores[card.suit] += 3
			CardData.Rank.J: suit_scores[card.suit] += 2

	# Find the suit with the highest score
	var best_suit = suit_scores.keys()[0]
	var max_score = suit_scores.values()[0]
	for suit in suit_scores:
		if suit_scores[suit] > max_score:
			max_score = suit_scores[suit]
			best_suit = suit
			
	return best_suit