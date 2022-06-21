tool
class_name VargenDock
extends VBoxContainer

export (String) var field_prefix = "_" setget set_field_prefix

signal run_pressed(sender, options)

const INDICATOR_COLLAPSED = preload("res://addons/vargen/icon_GUI_tree_arrow_right.svg")
const INDICATOR_REVEALED = preload("res://addons/vargen/icon_GUI_tree_arrow_down.svg")

onready var _warning_label: Label = $"WarningLabel"
onready var _run_button: Button = $"RunButton"
onready var _collapse_options_indicator: TextureRect = $"HBoxContainer/Indicator"
onready var _options_container: Control = $"OptionsContainer"
onready var _prefix_edit: LineEdit = $"OptionsContainer/HBoxContainer/PrefixEdit"

var _is_collapsed: bool = true setget _set_is_collapsed
var _is_run_enabled: bool = false
var _warning_message: String = ""

func set_field_prefix(val: String) -> void:
	field_prefix = val
	_prefix_edit.text = val


func set_is_run_enabled(enabled: bool, reason: String) -> void:
	_is_run_enabled = enabled
	_warning_message = reason
	if is_inside_tree():
		_warning_label.visible = !reason.empty()
		_run_button.disabled = !enabled
		_warning_label.text = reason


func _set_is_collapsed(val: bool) -> void:
	_is_collapsed = val
	_options_container.visible = !val
	_collapse_options_indicator.texture = INDICATOR_COLLAPSED if val else INDICATOR_REVEALED


func _on_HBoxContainer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_set_is_collapsed(!_is_collapsed)


func _on_RunButton_pressed() -> void:
	emit_signal("run_pressed",
		self,
		{
			field_prefix = _prefix_edit.text
		})
