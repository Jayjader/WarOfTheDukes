
extends Control

signal new_game_started

func _on_new_game_pressed():
	new_game_started.emit()

func _ready():
	$PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/NewGame.grab_focus()
