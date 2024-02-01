@tool
extends Control


signal lobby_ready(orf_is_computer: bool, wulf_is_computer: bool)

@onready var orf: Button = %OrfIsComputer
@onready var wulf: Button = %WulfIsComputer

func _on_confirm_pressed():
	lobby_ready.emit(orf.is_pressed(), wulf.is_pressed())

func _ready():
	%Confirm.grab_focus()
