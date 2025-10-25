extends VSlider

signal blur

export  var echo := 0.02
var echoCnt = 0

func _ready():
	set_process(false)
	connect("focus_entered", self, "_focusEntered")
	connect("focus_exited", self, "_focusExited")

func _focusEntered():
	set_process(true)
	echoCnt = 0

func _focusExited():
	set_process(false)

func _process(delta):
	if has_focus():
		if Input.is_joy_button_pressed(0, JOY_DPAD_DOWN) or Input.is_joy_button_pressed(0, JOY_DPAD_UP):
			echoCnt += delta
			if echoCnt > echo:
				echoCnt -= echo
				if Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
					value -= step
				if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
					value += step
		else:
			echoCnt = 0

func _on_VSlider_focus_exited():
	focus_mode = Control.FOCUS_NONE

func _on_Label_pressed():
	focus_mode = Control.FOCUS_ALL
	grab_focus()

func _gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		emit_signal("blur")
