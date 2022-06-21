tool
extends EditorPlugin

const DOCK_SCENE = preload("res://addons/vargen/vargen_dock.tscn")
const ONREADY_BLOCK_START = "\nonready "

var _dock
var _preferences: VargenPreferences
var _selection: EditorSelection
var _interface: EditorInterface

func _enter_tree() -> void:
	_interface = get_editor_interface()
	_selection = _interface.get_selection()
	_selection.connect("selection_changed", self, "_on_selection_changed")

	_dock = DOCK_SCENE.instance()
	_dock.connect("run_pressed", self, "_on_run_pressed")
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)
	_load_preferences()


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	if _preferences != null:
		_preferences = null
		_preferences.free()

	if _dock != null:
		_dock = null
		_dock.free()


func _on_selection_changed() -> void:
	_dock.set_is_run_enabled(true, "")


func _on_run_pressed(sender: VargenDock, options: Dictionary) -> void:
	_save_preferences(options)

	var root_node = _interface.get_edited_scene_root()
	var nodes = _selection.get_selected_nodes()

	if not _validate_selection(root_node, nodes):
		return

	var script = root_node.get_script()
	var source_code = script.source_code
	var insert_position = _find_insert_position(source_code)

	for node in nodes:
		var line = _make_line(node, root_node, options)
		source_code = source_code.insert(insert_position, line)

	var file = File.new()
	file.open(script.resource_path, File.WRITE)
	file.store_string(source_code)
	file.close()
	script.source_code = source_code

	_interface.set_main_screen_editor("Script")
	_interface.edit_script(script)
	_interface.get_script_editor()._reload_scripts()


func _find_insert_position(source_code: String) -> int:
	var insert_pos = source_code.find(ONREADY_BLOCK_START)

	if insert_pos < 0:
		insert_pos = source_code.length()
	else:
		insert_pos += 1

	return insert_pos


func _make_line(node: Node, root_node: Node, options: Dictionary) -> String:
	var namer = VargenSnakeNamer.new()
	var variable_name = namer.var_name_from_node(node)
	var type_name = node.get_class()
	return "onready var %s%s: %s = $\"%s\"\n" % [options.prefix, variable_name, type_name, root_node.get_path_to(node)]


func _save_preferences(options: Dictionary) -> void:
	_preferences.field_prefix = options.prefix
	ResourceSaver.save("res://addons/vargen/vargen_preferences.tres", _preferences)


func _load_preferences() -> void:
	_preferences = ResourceLoader.load("res://addons/vargen/vargen_preferences.tres") as VargenPreferences
	_dock.field_prefix = _preferences.field_prefix


func _validate_selection(root_node: Node, selected_nodes: Array) -> bool:
	if root_node == null:
		_dock.set_is_run_enabled(false, "No root node found. Try saving your scene first.")
		return false

	var root_script = root_node.get_script()
	if root_script == null:
		_dock.set_is_run_enabled(false, "Current scene root doesn't have a script attached.")
		return false

	if not root_script is GDScript:
		_dock.set_is_run_enabled(false, "Scene root script is not a GDScript.")
		return false

	if selected_nodes.size() == 0:
		_dock.set_is_run_enabled(false, "No nodes selected in the scene explorer.")
		return false

	return true
