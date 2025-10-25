extends MarginContainer

# Public slider value (in UI E$)
var value = 0 setget _set_value

# Cached nodes (optional)
onready var box    = get_node_or_null("HBoxContainer/VBoxContainer")
onready var _label = get_node_or_null("HBoxContainer/VBoxContainer/MarginContainer/Label")
onready var _vs    = get_node_or_null("HBoxContainer/VBoxContainer/SliderCenter/VSlider")

var disabled setget _set_disabled
export var format = "%s E$"

signal valueChanged(to)

func _set_disabled(how):
	# Do not hide the whole control; only its internals to keep layout stable
	if box:
		box.visible = not how
	else:
		visible = not how

func _set_value(to):
	# Clamp to slider range if present
	if _vs:
		var minv = float(_vs.min_value)
		var maxv = float(_vs.max_value)
		to = clamp(float(to), minv, maxv)
	value = to

	# Sync slider knob if needed
	if _vs and float(_vs.value) != float(to):
		_vs.value = to

	# Update label
	if _label:
		_label.text = format % CurrentGame.formatThousands(value)

func _ready():
	# Ensure initial UI reflects the current value
	if _vs and float(_vs.value) != float(value):
		_vs.value = value
	if _label:
		_label.text = format % CurrentGame.formatThousands(value)

func grab_focus():
	if _label:
		_label.grab_focus()

func _on_VSlider_value_changed(v):
	value = v
	emit_signal("valueChanged", v)
	if _label:
		_label.text = format % CurrentGame.formatThousands(value)
