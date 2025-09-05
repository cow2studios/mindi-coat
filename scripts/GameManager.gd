# Brain of the game
extends Node2D

## SIGNALS ##
signal hukum_updated(suit_name)
signal game_over(message)
signal lead_suit_updated(suit_name)

const CardScene = preload("res://scenes/Card.tscn")
const ShuffleAnimationScene = preload("res://scenes/ShuffleAnimation.tscn")

# -- Node References --
@onready var player_hand_pos = $PlayerHandPos
@onready var partner_hand_pos = $PartnerHandPos
@onready var left_opponent_pos = $LeftOpponentPos
@onready var right_opponent_pos = $RightOpponentPos
@onready var play_area_pos = $PlayAreaPos
@onready var timer = $Timer
@onready var hud = $HUD
@onready var pause_menu = $PauseMenu
@onready var sort_button = $SortButton
@onready var pause_button = $PauseButton

# -- Game State --
enum GameState {PLAYER_TURN, AI_TURN, EVALUATING, WAITING}
var current_state = GameState.WAITING

# -- Game Logic Variables --
var players_hands: Array = []
var cards_on_table: Array[CardData] = []
var player_who_played: Array[int] = []
var cards_played_this_round: Array[CardData] = [] # The AI's memory
var current_turn_index = 0
var trick_leader_index = 0
var hukum_suit: CardData.Suit
var is_hukum_set = false
var team_tricks_captured: Array = [[], []]
var team_mindi_count = [0, 0]
var team_trick_wins = [0, 0]

func _ready():
	timer.timeout.connect(on_timer_timeout)
	game_over.connect(hud.show_game_over)
	sort_button.pressed.connect(sort_player_hand)
	pause_button.pressed.connect(toggle_pause)
	start_new_game()

func start_new_game():
	# --- Reset game variables ---
	players_hands.clear()
	for i in range(4):
		var typed_hand: Array[CardData] = []
		players_hands.append(typed_hand)

	cards_on_table.clear(); player_who_played.clear()
	cards_played_this_round.clear() # Clear the AI's memory
	is_hukum_set = false; team_tricks_captured = [[], []];
	team_mindi_count = [0, 0]
	team_trick_wins = [0, 0]

	hud.game_over_panel.hide()
	
	for node in get_tree().get_nodes_in_group("cards"):
		node.queue_free()

	# --- Play the Shuffle Animation ---
	var shuffle_anim = ShuffleAnimationScene.instantiate()
	add_child(shuffle_anim)
	shuffle_anim.global_position = play_area_pos.position
	
	var anim_player = shuffle_anim.get_node("AnimationPlayer")
	
	SoundManager.play("card-shuffle")
	anim_player.play("shuffle")
	
	await anim_player.animation_finished
	
	shuffle_anim.queue_free()
	
	# --- Deal cards ---
	var deck = Deck.get_shuffled_deck()
	for i in range(13):
		for player_index in range(4):
			players_hands[player_index].append(deck.pop_front())
	
	await deal_cards_animation()
	
	# --- Start the game ---
	trick_leader_index = 0
	start_next_trick()

func play_card(card_data: CardData, player_index: int):
	players_hands[player_index].erase(card_data)
	cards_on_table.append(card_data)
	player_who_played.append(player_index)
	SoundManager.play("card-place")
	
	if cards_on_table.size() == 1:
		emit_signal("lead_suit_updated", CardData.Suit.keys()[card_data.suit])
	
	if not is_hukum_set and cards_on_table.size() > 1:
		var lead_suit = cards_on_table[0].suit
		if card_data.suit != lead_suit:
			is_hukum_set = true
			hukum_suit = card_data.suit
			var suit_name = CardData.Suit.keys()[hukum_suit]
			emit_signal("hukum_updated", suit_name)
	
	display_card_on_table(card_data, player_index)
	redraw_hands()
	
	if cards_on_table.size() == 4:
		current_state = GameState.EVALUATING
		timer.start(1.5)
	else:
		next_turn()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false
		pause_menu.hide()
	else:
		get_tree().paused = true
		var current_lead_suit = null
		if not cards_on_table.is_empty():
			current_lead_suit = cards_on_table[0].suit
		pause_menu.update_info(team_mindi_count, is_hukum_set, hukum_suit, current_lead_suit)
		pause_menu.show()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func sort_player_hand():
	var suit_order = {
		CardData.Suit.SPADES: 0, CardData.Suit.DIAMONDS: 1,
		CardData.Suit.CLUBS: 2, CardData.Suit.HEARTS: 3
	}
	players_hands[0].sort_custom(func(a, b):
		var suit_a_priority = suit_order[a.suit]
		var suit_b_priority = suit_order[b.suit]
		if suit_a_priority == suit_b_priority:
			return a.value > b.value
		else:
			return suit_a_priority < suit_b_priority
	)
	redraw_hands()
	SoundManager.play("card-fan")

func _on_card_clicked(card_data: CardData):
	if current_state != GameState.PLAYER_TURN: return
	var legal_moves = get_legal_moves(0)
	if card_data in legal_moves:
		play_card(card_data, 0)
	else:
		print("Illegal move! You must follow the lead suit.")

func get_legal_moves(player_index: int) -> Array[CardData]:
	var hand: Array[CardData] = players_hands[player_index]
	if cards_on_table.is_empty(): return hand
	var lead_suit = cards_on_table[0].suit
	var moves_in_suit: Array[CardData] = []
	for card in hand:
		if card.suit == lead_suit: moves_in_suit.append(card)
	if not moves_in_suit.is_empty(): return moves_in_suit
	else: return hand

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
	team_trick_wins[winner_team] += 1

	for card in cards_on_table:
		if card.rank == CardData.Rank._10: team_mindi_count[winner_team] += 1
	
	cards_played_this_round.append_array(cards_on_table)
	team_tricks_captured[winner_team].append_array(cards_on_table)
	
	cards_on_table.clear(); player_who_played.clear()
	for node in get_tree().get_nodes_in_group("table_cards"):
		node.queue_free()
	
	if players_hands[0].is_empty():
		end_round()
	else:
		start_next_trick()

func end_round():
	current_state = GameState.WAITING
	var final_message = ""
	
	if team_mindi_count[0] > team_mindi_count[1]:
		final_message = "Your  Team  Wins!\nScore: %s - %s" % [team_mindi_count[0], team_mindi_count[1]]
		if team_mindi_count[1] == 0: final_message += "\nOpponent  has  COAT!"
	elif team_mindi_count[1] > team_mindi_count[0]:
		final_message = "Opponents  Win!\nScore: %s - %s" % [team_mindi_count[0], team_mindi_count[1]]
		if team_mindi_count[0] == 0: final_message += "\nYour  team  has  COAT!"
	else: # Mindi count is 2-2, check the tie-breaker
		if team_trick_wins[0] > team_trick_wins[1]:
			final_message = "Your  Team  Wins  on  Tricks!\nTricks: %s - %s" % [team_trick_wins[0], team_trick_wins[1]]
		elif team_trick_wins[1] > team_trick_wins[0]:
			final_message = "Opponents  Win  on  Tricks!\nTricks: %s - %s" % [team_trick_wins[1], team_trick_wins[0]]
		else: # Extremely rare case of 7-6 tricks and a 2-2 Mindi split, resulting in a true draw
			final_message = "It's a True Draw!\nScore: 2 - 2"

	hud.show()
	emit_signal("game_over", final_message)

func next_turn():
	current_turn_index = (current_turn_index + 1) % 4
	set_turn_state()

func start_next_trick():
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

func do_ai_turn():
	if current_state != GameState.AI_TURN: return
	var legal_moves = get_legal_moves(current_turn_index)
	if not legal_moves.is_empty():
		var card_to_play = choose_best_card(current_turn_index, legal_moves)
		play_card(card_to_play, current_turn_index)
	else: print("ERROR: AI has no legal moves")

func deal_cards_animation():
	for node in get_tree().get_nodes_in_group("player_hand_cards"):
		node.queue_free()
	
	var hand_positions = [player_hand_pos, right_opponent_pos, partner_hand_pos, left_opponent_pos]
	
	for j in range(players_hands[0].size()):
		for i in range(4):
			var player_index = i
			var hand = players_hands[player_index]
			if j >= hand.size(): continue

			var card_data = hand[j]
			var is_human = (player_index == 0)
			
			var card_instance = CardScene.instantiate()
			add_child(card_instance)
			
			card_instance.global_position = play_area_pos.global_position
			card_instance.display_card(card_data, is_human)
			
			SoundManager.play("card-slide")
			
			var final_pos = hand_positions[player_index].position
			var player_card_spacing = 90
			var enemy_card_spacing = 20
			var card_rotation_degrees = 0
			
			if i == 1 or i == 3: # Left and Right opponents
				card_rotation_degrees = 90
				var total_size = (hand.size() - 1) * enemy_card_spacing
				var start_offset = - total_size / 2.0
				final_pos.y += start_offset + (j * enemy_card_spacing)
			else: # Human and Partner
				var total_size = (hand.size() - 1) * player_card_spacing
				var start_offset = - total_size / 2.0
				final_pos.x += start_offset + (j * player_card_spacing)
			
			var tween = create_tween()
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
			tween.tween_property(card_instance, "global_position", final_pos, 0.4)
			tween.tween_property(card_instance, "rotation_degrees", card_rotation_degrees, 0.4)
			
			if is_human:
				card_instance.card_clicked.connect(_on_card_clicked)
			
			card_instance.add_to_group("player_hand_cards")
			card_instance.add_to_group("cards")
		
		await get_tree().create_timer(0.12).timeout

func redraw_hands():
	for node in get_tree().get_nodes_in_group("player_hand_cards"):
		node.queue_free()
	
	var hand_positions = [player_hand_pos, right_opponent_pos, partner_hand_pos, left_opponent_pos]
	
	for i in range(4):
		var player_index = i
		var hand = players_hands[player_index]
		var is_human = (player_index == 0)
		var pos = hand_positions[player_index].position
		
		var player_card_spacing = 90
		var enemy_card_spacing = 20
		var card_rotation_degrees = 0
		if i == 1 or i == 3:
			card_rotation_degrees = 90
		
		var total_size = (hand.size() - 1) * (enemy_card_spacing if (i == 1 or i == 3) else player_card_spacing)
		var start_offset = - total_size / 2.0
		
		for j in range(hand.size()):
			var card_data = hand[j]
			var card_instance = CardScene.instantiate()
			add_child(card_instance)
			
			var card_pos = Vector2.ZERO
			if card_rotation_degrees == 90:
				card_pos.y = start_offset + (j * enemy_card_spacing)
			else:
				card_pos.x = start_offset + (j * player_card_spacing)
			
			card_instance.position = pos + card_pos
			card_instance.rotation_degrees = card_rotation_degrees
			card_instance.display_card(card_data, is_human)
			
			if is_human:
				card_instance.card_clicked.connect(_on_card_clicked)
			
			card_instance.add_to_group("player_hand_cards")
			card_instance.add_to_group("cards")

func display_card_on_table(card_data: CardData, player_index: int):
	var card_instance = CardScene.instantiate()
	add_child(card_instance)
	var offset = Vector2.ZERO
	match player_index:
		0: offset = Vector2(0, 75);
		1: offset = Vector2(75, 0);
		2: offset = Vector2(0, -75);
		3: offset = Vector2(-75, 0);
	card_instance.position = play_area_pos.position + offset
	card_instance.display_card(card_data)
	card_instance.add_to_group("table_cards"); card_instance.add_to_group("cards")

func get_trick_context():
	var context = {"winning_card": null, "winning_player": - 1, "has_mindi": false, "is_strong_win": false}
	if cards_on_table.is_empty(): return context
	context.winning_card = cards_on_table[0]; context.winning_player = player_who_played[0]
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
	for card in cards_on_table:
		if card.rank == CardData.Rank._10: context.has_mindi = true; break
	if (is_hukum_set and context.winning_card.suit == hukum_suit) or context.winning_card.value >= 13:
		context.is_strong_win = true
	return context

func choose_best_card(player_index: int, legal_moves: Array[CardData]) -> CardData:
	legal_moves.sort_custom(func(a, b): return a.value < b.value)
	var lowest_card = legal_moves[0]

	# SCENARIO A: AI is leading the trick
	if cards_on_table.is_empty():
		# Endgame Logic
		if legal_moves.size() <= 3:
			var highest_card_in_hand = legal_moves[-1]
			var is_highest_remaining = true
			for card in cards_played_this_round:
				if card.suit == highest_card_in_hand.suit and card.value > highest_card_in_hand.value:
					is_highest_remaining = false
					break
			if is_highest_remaining:
				print("AI ENDGAME: Playing highest remaining card!")
				return highest_card_in_hand

		# Card Counting Logic
		if is_hukum_set:
			var ace_of_hukum_played = false
			for card in cards_played_this_round:
				if card.suit == hukum_suit and card.rank == CardData.Rank.A:
					ace_of_hukum_played = true
					break
			if ace_of_hukum_played:
				for card in legal_moves:
					if card.suit == hukum_suit and card.rank == CardData.Rank.K:
						return card

		# Standard High-Card Lead Logic
		var high_cards = legal_moves.filter(func(card): return card.value >= 13 and (not is_hukum_set or card.suit != hukum_suit))
		if not high_cards.is_empty():
			return high_cards[-1]
		
		return lowest_card

	# SCENARIO B: AI is following
	var context = get_trick_context()
	var partner_is_winning = context.winning_player % 2 == player_index % 2

	# If partner is winning, play safe or assist
	if partner_is_winning:
		var lead_suit = cards_on_table[0].suit
		var can_follow_suit = lowest_card.suit == lead_suit
		
		if can_follow_suit and context.is_strong_win:
			var mindi_card = null
			for card in legal_moves:
				if card.rank == CardData.Rank._10:
					mindi_card = card
					break
			
			if mindi_card:
				## NEW & IMPROVED: Danger Check Logic ##
				var unaccounted_high_cards = []
				# Find which high cards are still missing
				var high_card_ranks = [CardData.Rank.A, CardData.Rank.K, CardData.Rank.Q, CardData.Rank.J]
				for rank_to_check in high_card_ranks:
					var is_accounted_for = false
					# Check AI's own hand
					for c in players_hands[player_index]:
						if c.suit == lead_suit and c.rank == rank_to_check: is_accounted_for = true; break
					if is_accounted_for: continue
					# Check memory of played cards
					for c in cards_played_this_round:
						if c.suit == lead_suit and c.rank == rank_to_check: is_accounted_for = true; break
					# If not found, it's a potential threat
					if not is_accounted_for:
						unaccounted_high_cards.append(rank_to_check)
				
				# Now check if we hold all the threatening cards
				var has_all_threats = true
				for threat_rank in unaccounted_high_cards:
					var has_this_threat = false
					for c in players_hands[player_index]:
						if c.suit == lead_suit and c.rank == threat_rank: has_this_threat = true; break
					if not has_this_threat:
						has_all_threats = false
						break
				
				# Only play the mindi if there are no outstanding threats
				if has_all_threats:
					print("AI Player %s is SAFELY assisting partner!" % player_index)
					return mindi_card

		# Discard Logic if not assisting
		if not can_follow_suit:
			var full_hand = players_hands[player_index]
			full_hand.sort_custom(func(a, b): return a.value < b.value)
			for card in full_hand:
				if is_hukum_set and card.suit != hukum_suit: return card
			return full_hand[0]
		# Default safe play
		return lowest_card
	
	# If an opponent is winning
	else:
		var lead_suit = cards_on_table[0].suit
		var can_follow_suit = lowest_card.suit == lead_suit
		if can_follow_suit:
			var cards_that_can_win = legal_moves.filter(func(card): return card.value > context.winning_card.value)
			if not cards_that_can_win.is_empty():
				return cards_that_can_win[0]
			else:
				return lowest_card
		else: # Cannot follow suit
			# Hukum Setting Logic
			if not is_hukum_set:
				var best_suit_to_set = choose_best_hukum_suit(players_hands[player_index], lead_suit)
				for card in legal_moves:
					if card.suit == best_suit_to_set: return card
			
			# Trumping Logic
			var hukum_cards = legal_moves.filter(func(card): return card.suit == hukum_suit)
			if not hukum_cards.is_empty():
				# Partner Signaling Logic
				var partner_has_trumped = false
				for i in range(cards_on_table.size()):
					if player_who_played[i] % 2 == player_index % 2 and cards_on_table[i].suit == hukum_suit:
						partner_has_trumped = true
						break
				
				if not partner_has_trumped or context.winning_card.suit == hukum_suit:
					if context.has_mindi or context.winning_card.suit == hukum_suit:
						return hukum_cards[0]
		
		# Default discard
		return lowest_card

func choose_best_hukum_suit(hand: Array[CardData], lead_suit: CardData.Suit) -> CardData.Suit:
	var suit_scores = {CardData.Suit.SPADES: 0, CardData.Suit.HEARTS: 0, CardData.Suit.DIAMONDS: 0, CardData.Suit.CLUBS: 0, }
	suit_scores.erase(lead_suit)
	for card in hand:
		if card.suit == lead_suit: continue
		suit_scores[card.suit] += 1
		match card.rank:
			CardData.Rank.A: suit_scores[card.suit] += 5
			CardData.Rank.K: suit_scores[card.suit] += 4
			CardData.Rank.Q: suit_scores[card.suit] += 3
			CardData.Rank.J: suit_scores[card.suit] += 2
	var best_suit = suit_scores.keys()[0]
	var max_score = suit_scores.values()[0]
	for suit in suit_scores:
		if suit_scores[suit] > max_score: max_score = suit_scores[suit]; best_suit = suit
	return best_suit