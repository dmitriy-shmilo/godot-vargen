tool
extends EditorPlugin

const ONREADY_BLOCK_START = "\nonready "

var _dock: VargenDock
var _preferences: VargenPreferences

func _enter_tree() -> void:
	_dock = load("res://addons/vargen/vargen_dock.tscn").instance()
	_dock.connect("run_pressed", self, "_on_run_pressed")
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)
	_load_preferences()


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	if _dock != null:
		_dock.queue_free()


func _on_run_pressed(sender: VargenDock, options: Dictionary) -> void:
	_save_preferences(options)

	var interface = get_editor_interface()
	var root_node = interface.get_edited_scene_root()
	if root_node == null:
		printerr("VarGen: No root node found. Try saving your scene first.")
		return

	var script = root_node.get_script()

	if script == null:
		printerr("VarGen: Current scene root doesn't have a script attached.")
		return

	if not script is GDScript:
		printerr("VarGen: Scene root script is not a GDScript.")
		return

	var selection = interface.get_selection()
	var nodes = selection.get_selected_nodes()

	if nodes.size() == 0:
		printerr("VarGen: No nodes selected in the scene explorer.")
		return

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
	interface.set_main_screen_editor("Script")

	interface.edit_script(script)
	interface.get_script_editor()._reload_scripts()


func _find_insert_position(source_code: String) -> int:
	var insert_pos = source_code.find(ONREADY_BLOCK_START)

	if insert_pos < 0:
		insert_pos = source_code.length()
	else:
		insert_pos += 1

	return insert_pos


func _make_line(node: Node, root_node: Node, options: Dictionary) -> String:
	var a = "A".to_ascii()[0]
	var z = "Z".to_ascii()[0]
	var underscore = "_".to_ascii()[0]
	var name = node.get_name()
	var type_name = node.get_class()
	var name_array = PoolByteArray(name.to_ascii())
	var name_result_array = PoolByteArray()

	var is_upper = true
	for c in name.to_ascii():
		if c >= a and c <= z and not is_upper:
			name_result_array.append(underscore)
			is_upper = true
		elif is_upper:
			is_upper = false
		name_result_array.append(c)
	name = name_result_array.get_string_from_ascii().to_lower()
	return "onready var %s%s: %s = $\"%s\"\n" % [options.prefix, name, type_name, root_node.get_path_to(node)]


func _save_preferences(options: Dictionary) -> void:
	_preferences.field_prefix = options.prefix
	ResourceSaver.save("res://addons/vargen/vargen_preferences.tres", _preferences)


func _load_preferences() -> void:
	_preferences = ResourceLoader.load("res://addons/vargen/vargen_preferences.tres") as VargenPreferences
	_dock.field_prefix = _preferences.field_prefix
