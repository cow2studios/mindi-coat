# scripts/HUD.gd attached to hud
extends CanvasLayer

## NODE PATHS ##
@onready var score_label = $MainContainer/MarginContainer/VBoxContainer/ScoreLabel
@onready var hukum_label = $MainContainer/MarginContainer/VBoxContainer/HukumLabel
@onready var game_over_panel = $MainContainer/CenterContainer/GameOverPanel
@onready var game_over_label = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/GameOverLabel
@onready var new_game_button = $MainContainer/CenterContainer/GameOverPanel/VBoxContainer/NewGameButton

func _ready():
	# Connect this button's "pressed" signal back to the GameManager
	new_game_button.pressed.connect(get_parent().start_new_game)
	game_over_panel.hide()

func update_score(team_scores):
	score_label.text = "Mindi Captured -> Your Team: %s | Opponents: %s" % [team_scores[0], team_scores[1]]

func update_hukum(suit_name):
	if suit_name == "None":
		hukum_label.text = "Hukum: Not Set"
	else:
		hukum_label.text = "Hukum: " + suit_name

func show_game_over(message):
	game_over_label.text = message
	game_over_panel.show()
