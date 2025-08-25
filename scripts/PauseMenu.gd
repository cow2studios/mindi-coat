# scripts/pause_menu.gd
extends CanvasLayer

# --- Node References ---
@onready var your_team_score_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/YourTeamScoreLabel
@onready var opponent_score_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/OpponentScoreLabel
@onready var hukum_value_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/HukumBoxPanel/HukumBox/HukumValueLabel
@onready var lead_suit_value_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/LeadSuitBoxPanel/LeadSuitBox/LeadSuitValueLabel
@onready var resume_button = $CenterContainer/VBoxContainer/ResumeButton

func _ready():
	resume_button.pressed.connect(unpause_game)
	# The line for the RulesButton has been removed.

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and get_tree().paused:
		unpause_game()
		get_viewport().set_input_as_handled()

# This function will be called by the GameManager to update the score
func update_info(score, hukum_set, hukum_suit, lead_suit):
	your_team_score_label.text = "Your Team: %s" % score[0]
	opponent_score_label.text = "Opponents: %s" % score[1]

	if hukum_set:
		hukum_value_label.text = CardData.Suit.keys()[hukum_suit].capitalize()
	else:
		hukum_value_label.text = "Not Set"
		
	if lead_suit:
		lead_suit_value_label.text = CardData.Suit.keys()[lead_suit].capitalize()
	else:
		lead_suit_value_label.text = "None"

func unpause_game():
	get_tree().paused = false
	hide()
