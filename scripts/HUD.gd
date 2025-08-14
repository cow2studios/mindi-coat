# scripts/HUD.gd attached to hud
extends CanvasLayer

# --- Node references ---
@onready var your_team_score_label = $MainContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/YourTeamScoreLabel
@onready var opponent_score_label = $MainContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/OpponentScoreLabel
@onready var hukum_value_label = $MainContainer/MarginContainer/VBoxContainer/HukumBoxPanel/HukumBox/HukumValueLabel
@onready var lead_suit_value_label = $MainContainer/MarginContainer/VBoxContainer/LeadSuitBoxPanel/LeadSuitBox/LeadSuitValueLabel

# --- Game Over references ---
@onready var game_over_panel = $MainContainer/CenterContainer/GameOverPanel
@onready var game_over_label = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/GameOverLabel
@onready var new_game_button = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/NewGameButton
@onready var rules_button = $MainContainer/RulesButton

func _ready():
	new_game_button.pressed.connect(get_parent().start_new_game)
	game_over_panel.hide()
	rules_button.pressed.connect(UIManager.show_rules_popup)

func update_score(team_scores):
	your_team_score_label.text = "Your Team: %s" % team_scores[0]
	opponent_score_label.text = "Opponents: %s" % team_scores[1]

func update_hukum(suit_name):
	if suit_name == "None":
		hukum_value_label.text = "Not Set"
	else:
		hukum_value_label.text = suit_name.capitalize()

func update_lead_suit(suit_name):
	if suit_name == "None":
		lead_suit_value_label.text = "None"
	else:
		lead_suit_value_label.text = suit_name.capitalize()

func show_game_over(message):
	game_over_label.text = message
	game_over_panel.show()
