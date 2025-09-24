# Controls a single visual card, showing either its face or back.
extends Area2D

signal card_clicked(card_data)

@onready var mindi_outline = $MindiOutline
@onready var hukum_outline = $HukumOutline

var card_data: CardData

func update_hukum_status(current_hukum_suit):
	if not is_instance_valid(card_data):
		return
		
	if $CardSprite.visible and current_hukum_suit != null and card_data.suit == current_hukum_suit:
		hukum_outline.show()
	else:
		hukum_outline.hide()

func display_card(data: CardData, show_face: bool = true):
	self.card_data = data
	
	if not is_instance_valid(card_data):
		mindi_outline.hide()
		hukum_outline.hide()
		return

	if show_face:
		$CardSprite.texture = card_data.texture
		$CardSprite.visible = true
		$CardBack.visible = false
		
		if card_data.rank == CardData.Rank._10:
			mindi_outline.show()
		else:
			mindi_outline.hide()
			
	else:
		$CardSprite.visible = false
		$CardBack.visible = true
		mindi_outline.hide()
		hukum_outline.hide()

	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("card_clicked", card_data)