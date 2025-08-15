# Controls a single visual card, showing either its face or back.
extends Area2D

signal card_clicked(card_data)

var card_data: CardData

func display_card(data: CardData, show_face: bool = true):
	self.card_data = data
	$CardSprite.texture = card_data.texture
	$CardSprite.visible = show_face
	$CardBack.visible = not show_face
	
	input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_clicked", card_data)
