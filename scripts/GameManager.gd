# scripts/GameManager.gd attached to Main.tcsn
extends Node2D

const CardScene = preload("res://scenes/Card.tscn")

# -- Node References --
@onready var player_hand_pos = $PlayerHandPos
@onready var play_area_pos = $PlayAreaPos
@onready var timer = $Timer # Reference to the new Timer node

# -- Game State --
# We use a state machine to control what can happen at any given time
enum GameState {PLAYER_TURN, AI_TURN, EVALUATING, WAITING}
var current_state = GameState.WAITING

# -- Game Logic Variables --
var players_hands: Array = [[], [], [], []] # 0: Player, 1: Left, 2: Partner, 3: Right
var cards_on_table: Array[CardData] = []
var current_turn_index = 0

func _ready():
	# Connect the timer's timeout signal to a function that will handle the AI's turn
	timer.timeout.connect(do_ai_turn)
	start_new_game()

func start_new_game():
	# --- Reset game variables ---
	players_hands = [[], [], [], []]
	cards_on_table.clear()
	# Clear any old card visuals
	for node in get_tree().get_nodes_in_group("cards"):
		node.queue_free()

	# --- Deal cards ---
	var deck = Deck.get_shuffled_deck()
	for i in range(13):
		for player_index in range(4):
			players_hands[player_index].append(deck.pop_front())
	
	display_player_hand()
	
	# --- Start the game ---
	current_turn_index = 0 # Player 0 starts the first trick
	current_state = GameState.PLAYER_TURN
	print("Your turn to play.")

# This function is called when ANY player (human or AI) plays a card
func play_card(card_data: CardData, player_index: int):
	# 1. Remove the card from the player's hand data
	players_hands[player_index].erase(card_data)
	
	# 2. Add the card to the table data
	cards_on_table.append(card_data)
	
	# 3. Visually show the card on the table
	display_card_on_table(card_data, player_index)
	
	# 4. If it was the human player, update their hand visuals
	if player_index == 0:
		display_player_hand()
	
	# 5. Check if the trick is over
	if cards_on_table.size() == 4:
		current_state = GameState.EVALUATING
		print("Trick is over. Evaluating winner...")
		# We'll add evaluation logic later
	else:
		# If the trick is not over, move to the next player's turn
		next_turn()

# This is called when the human player clicks a card
func _on_card_clicked(card_data: CardData):
	# Only allow the player to act if it's their turn
	if current_state != GameState.PLAYER_TURN:
		return
		
	# For now, any card is a legal move. We'll add rules later.
	print("You played: %s of %s" % [CardData.Rank.keys()[card_data.rank], CardData.Suit.keys()[card_data.suit]])
	play_card(card_data, 0)

# This function manages turn order
func next_turn():
	current_turn_index = (current_turn_index + 1) % 4 # Move to the next player (0, 1, 2, 3, then back to 0)
	
	if current_turn_index == 0:
		current_state = GameState.PLAYER_TURN
		print("Your turn to play.")
	else:
		current_state = GameState.AI_TURN
		# Instead of instantly playing, we start a timer for a short delay
		timer.start(0.75) # Wait 0.75 seconds before the AI plays

# This function runs when the Timer finishes
func do_ai_turn():
	print("AI Player %s is thinking..." % current_turn_index)
	# --- Super Simple AI Logic ---
	# The AI will just play the first card in its hand.
	var ai_hand = players_hands[current_turn_index]
	if not ai_hand.is_empty():
		var card_to_play = ai_hand[0]
		print("AI Player %s played: %s of %s" % [current_turn_index, CardData.Rank.keys()[card_to_play.rank], CardData.Suit.keys()[card_to_play.suit]])
		play_card(card_to_play, current_turn_index)

# This function redraws the player's entire hand.
func display_player_hand():
	# First, remove the old card visuals
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
		# Add card to a group for easy cleanup
		card_instance.add_to_group("player_hand_cards")
		card_instance.add_to_group("cards") # A general group for all cards

# This function places a visual card in the play area
func display_card_on_table(card_data: CardData, player_index: int):
	var card_instance = CardScene.instantiate()
	add_child(card_instance)
	
	# Position the card based on which player played it
	var offset = Vector2.ZERO
	match player_index:
		0: offset = Vector2(0, 50) # Bottom (Player)
		1: offset = Vector2(50, 0) # Right (Opponent)
		2: offset = Vector2(0, -50) # Top (Partner)
		3: offset = Vector2(-50, 0) # Left (Opponent)
		
	card_instance.position = play_area_pos.position + offset
	card_instance.display_card(card_data)
	card_instance.add_to_group("table_cards")
	card_instance.add_to_group("cards")