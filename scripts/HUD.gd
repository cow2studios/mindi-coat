# Controls the in-game UI.
extends CanvasLayer

@onready var your_team_score_label = $MainContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/YourTeamScoreLabel
@onready var opponent_score_label = $MainContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/OpponentScoreLabel
@onready var hukum_value_label = $MainContainer/MarginContainer/VBoxContainer/HukumBoxPanel/HukumBox/HukumValueLabel
@onready var lead_suit_value_label = $MainContainer/MarginContainer/VBoxContainer/LeadSuitBoxPanel/LeadSuitBox/LeadSuitValueLabel
@onready var rules_button = $MainContainer/RulesButton

@onready var game_over_panel = $MainContainer/CenterContainer/GameOverPanel
@onready var game_over_label = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/GameOverLabel
@onready var new_game_button = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/NewGameButton

func _ready():
	new_game_button.pressed.connect(_on_play_again_pressed)
	rules_button.pressed.connect(UIManager.show_rules_popup)
	game_over_panel.hide()

func _on_play_again_pressed():
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

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
