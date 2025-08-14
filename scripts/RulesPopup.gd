# scripts/rules_popup.gd attached to RulesPopup
extends CanvasLayer

@onready var close_button = $PanelContainer/VBoxContainer/CloseButton

func _ready():
	# When the close button is pressed, hide the entire popup
	close_button.pressed.connect(hide)