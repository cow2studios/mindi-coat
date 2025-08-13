extends Node2D

@export var suit: String
@export var rank: String
@export var value: int

func set_card(suit_name, rank_name, val, texture):
    suit = suit_name
    rank = rank_name
    value = val
    $TextureRect.texture = texture
