# scripts/CardData.gd not attached to any component.
# This script defines the data structure for a playing card.
extends Resource
class_name CardData

# Enum for the four suits
enum Suit {CLUBS, DIAMONDS, HEARTS, SPADES}

# Enum for the 13 ranks
enum Rank {_02, _03, _04, _05, _06, _07, _08, _09, _10, J, Q, K, A}

## The suit of the card (Clubs, Diamonds, etc.)
@export var suit: Suit

## The rank of the card (2, 10, Ace, etc.)
@export var rank: Rank

## The numeric value for comparing cards (2-14)
@export var value: int

## The texture/image for the card's face
@export var texture: Texture2D