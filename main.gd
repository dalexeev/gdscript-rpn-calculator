extends Control

var expr := preload('expr.gd').new()

onready var result := $Result as Label

func _on_text_changed(new_text: String) -> void:
	result.text = str(expr.evalute(new_text)) if new_text else ''
