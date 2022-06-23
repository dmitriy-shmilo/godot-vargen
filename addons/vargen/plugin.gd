tool
extends EditorPlugin

const DOCK_SCENE = preload("res://addons/vargen/vargen_dock.tscn")

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

	_preferences = null

	if _dock != null:
		_dock.free()
		_dock = null


func _on_selection_changed() -> void:
	_dock.set_is_run_enabled(true, "")


func _on_run_pressed(sender: VargenDock, options: Dictionary) -> void:
	_save_preferences(options)

	var root_node = _interface.get_edited_scene_root()
	var script = root_node.get_script()
	var nodes = _selection.get_selected_nodes()

	if not _validate_selection(root_node, nodes):
		return

	var composer: VargenScriptComposer
	var source_code: String
	var file = File.new()
	file.open(script.resource_path, File.READ_WRITE)

	if script is GDScript:
		composer = VargenGDScriptComposer.new()
		source_code = script.source_code
	elif script is CSharpScript:
		composer = VargenCSharpComposer.new()
		source_code = file.get_as_text()

	composer.variable_prefix = options.field_prefix
	composer.should_insert_nodes = options.insert_nodes
	composer.should_insert_signals = options.insert_signals
	source_code = composer.insert_onready_nodes(source_code, script, root_node, nodes)
	file.store_string(source_code)
	file.close()

	if script is GDScript:
		script.source_code = source_code
		_interface.set_main_screen_editor("Script")
		_interface.edit_script(script)
		_interface.get_script_editor()._reload_scripts() # undocumented call, sometimes generates an error
	elif script is CSharpScript:
		_interface.edit_script(script)


func _save_preferences(options: Dictionary) -> void:
	_preferences.field_prefix = options.field_prefix
	_preferences.insert_nodes = options.insert_nodes
	_preferences.insert_signals = options.insert_signals
	ResourceSaver.save("res://addons/vargen/vargen_preferences.tres", _preferences)


func _load_preferences() -> void:
	_preferences = ResourceLoader.load("res://addons/vargen/vargen_preferences.tres") as VargenPreferences
	_dock.field_prefix = _preferences.field_prefix
	_dock.insert_nodes = _preferences.insert_nodes
	_dock.insert_signals = _preferences.insert_signals


func _validate_selection(root_node: Node, selected_nodes: Array) -> bool:
	if root_node == null:
		_dock.set_is_run_enabled(false, "No root node found. Try saving your scene first.")
		return false

	var root_script = root_node.get_script()
	if root_script == null:
		_dock.set_is_run_enabled(false, "Current scene root doesn't have a script attached.")
		return false

	if not root_script is GDScript and not root_script is CSharpScript:
		_dock.set_is_run_enabled(false, "Scene root script is not a GDScript nor a C# Script.")
		return false

	if selected_nodes.size() == 0:
		_dock.set_is_run_enabled(false, "No nodes selected in the scene explorer.")
		return false

	return true
