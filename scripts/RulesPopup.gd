# Simple script for the reusable rules popup.
extends CanvasLayer

@onready var close_button = $PanelContainer/VBoxContainer/CloseButton

func _ready():
	close_button.pressed.connect(hide)