extends Control

@onready var texture_rect = $TextureRect
@onready var animation_player = $AnimationPlayer

func play(suit_texture: Texture):
	texture_rect.texture = suit_texture
	animation_player.play("hukum_reveal")
	# When the animation is done, the scene will remove itself.
	await animation_player.animation_finished
	queue_free()