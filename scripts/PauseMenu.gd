# scripts/pause_menu.gd
extends CanvasLayer

# --- Node References ---
@onready var your_team_score_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/YourTeamScoreLabel
@onready var opponent_score_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/ScoreBoxPanel/ScoreBox/ScoreValues/OpponentScoreLabel
@onready var hukum_value_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/HukumBoxPanel/HukumBox/HukumValueLabel
@onready var lead_suit_value_label = $CenterContainer/VBoxContainer/MarginContainer/VBoxContainer/LeadSuitBoxPanel/LeadSuitBox/LeadSuitValueLabel
@onready var resume_button = $CenterContainer/VBoxContainer/ResumeButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

func _ready():
	resume_button.pressed.connect(unpause_game)
	quit_button.pressed.connect(back_to_main_menu)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and get_tree().paused:
		unpause_game()
		get_viewport().set_input_as_handled()

func unpause_game():
	get_tree().paused = false
	hide()

func back_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")