# Manages showing and hiding global UI elements like the rules popup.
extends Node

var rules_popup_scene = preload("res://scenes/RulesPopup.tscn")
var rules_popup_instance

func _ready():
	rules_popup_instance = rules_popup_scene.instantiate()
	get_tree().root.add_child.call_deferred(rules_popup_instance)
	rules_popup_instance.hide()

func show_rules_popup():
	rules_popup_instance.show()