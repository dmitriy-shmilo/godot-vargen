class_name VargenGDScriptComposer
extends VargenScriptComposer

const ONREADY_BLOCK_START = "onready "
const CLASS_TOP_START = "extends "


func insert_onready_nodes(source: String, \
	script: Script, \
	root_node: Node, \
	selected_nodes: Array) -> String:

	# TODO: support inerting missing signal connections
	if not should_insert_nodes:
		return source

	var tabulation = ""
	var lines = source.split("\n")
	var class_top_index = -1
	var onready_block_index = -1
	var namer = VargenSnakeNamer.new()

	for i in range(lines.size()):
		var line = lines[i] as String

		if class_top_index < 0 and line.begins_with(CLASS_TOP_START):
			class_top_index = i
		elif onready_block_index < 0 and line.begins_with(ONREADY_BLOCK_START):
			onready_block_index = i

		if class_top_index >= 0 and onready_block_index >= 0:
			break

	var insert_index = lines.size()

	if onready_block_index >= 0:
		insert_index = onready_block_index
	elif class_top_index >= 0:
		insert_index = class_top_index
	else:
		# TODO: return an error instead of printing
		printerr("Can't find a place to insert fields in %s. Will append at the end of the file.")

	for i in range(selected_nodes.size()):
		var node = selected_nodes[i] as Node
		var var_name = namer.var_name_from_node(node)
		var type_name = node.get_class()
		var line = "onready var %s%s: %s = $\"%s\"" % [
			variable_prefix,
			var_name,
			type_name,
			root_node.get_path_to(node)
		]

		lines.insert(insert_index, line)
	return lines.join("\n")
