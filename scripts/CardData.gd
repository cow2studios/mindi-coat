# Defines the properties of a single card.
extends Resource
class_name CardData

enum Suit {CLUBS, DIAMONDS, HEARTS, SPADES}
enum Rank {_02, _03, _04, _05, _06, _07, _08, _09, _10, J, Q, K, A}

func is_mindi() -> bool:
    return rank == 10

@export var suit: Suit
@export var rank: Rank
@export var value: int
@export var texture: Texture2D