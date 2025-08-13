# scripts/Card.gd attached to Card
extends Area2D

signal card_clicked(card_data)

var card_data: CardData

func display_card(data: CardData):
	self.card_data = data
	$CardSprite.texture = card_data.texture
	# We will connect this signal from the GameManager
	input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_clicked", card_data)
