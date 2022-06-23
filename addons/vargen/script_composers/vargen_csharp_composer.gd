class_name VargenCSharpComposer
extends VargenScriptComposer

func insert_onready_nodes(source: String, \
	script: Script, \
	root_node: Node, \
	selected_nodes: Array \
) -> String:

	var tabulation = ""
	var lines = source.split("\n")
	var class_top_index = -1
	var ready_method_index = -1
	var class_bottom_index = -1

	# expected signal connections
	var signal_connections = {}

	if should_insert_signals:
		for node in selected_nodes:
			for sig in node.get_signal_list():
				for con in node.get_signal_connection_list(sig.name):
					if con.target == root_node:
						signal_connections[con.method] = {
							connection = con,
							signal = sig,
							found = false
						}

	for i in range(lines.size()):
		var line = lines[i] as String
		var tab_before_index = -1
		if class_top_index < 0 and "public class %s" % [script.resource_name] in line:
			class_top_index = i + 2 # assuming open bracket is next
		elif ready_method_index < 0:
			tab_before_index = line.find("public override void _Ready()")
			if tab_before_index >= 0:
				ready_method_index = i + 2 # assuming open bracket is next
				tabulation = line.substr(0, tab_before_index)

		for key in signal_connections.keys():
			if key in line:
				signal_connections[key].found = true

	# TODO: return an error instead of printing
	if class_top_index < 0:
		printerr("Can't find class %s in %s." % [script.resource_name, script.resource_path])
		return source

	if ready_method_index < 0:
		printerr("Can't find _Ready method in %s." % [script.resource_path])
		return source

	if should_insert_nodes:
		lines = insert_node_fields(lines, root_node, selected_nodes, \
			tabulation, class_top_index, ready_method_index)

	if should_insert_signals:
		# find the bottom of the last method
		for i in range(lines.size()):
			var line = lines[lines.size() - 1 - i]
			if class_bottom_index < 0 and line.begins_with("%s}" % [tabulation]):
				class_bottom_index = lines.size() - i
				break

		lines = insert_missing_signal_connections(lines, signal_connections, \
			tabulation, class_bottom_index)

	return lines.join("\n")


func insert_node_fields(lines: PoolStringArray, \
	root_node: Node, \
	selected_nodes: Array, \
	tabulation: String, \
	field_declaration_index: int, \
	field_init_index: int
) -> PoolStringArray:
	var keywords = VargenCsharpConstants.RESERVED_KEYWORDS
	var namer = VargenPascalNamer.new()

	for i in range(selected_nodes.size()):
		var node = selected_nodes[i] as Node
		var var_name = variable_prefix + namer.var_name_from_node(node)

		if keywords.has(var_name):
			var_name = "@" + var_name

		lines.insert(field_declaration_index + i, \
			"%sprivate %s %s = null;" % [
				tabulation,
				node.get_class(),
				var_name
		])

		# FIXME: this will break if field_init_index is less than field_declaration_index
		lines.insert(field_init_index + i * 2 + 1, \
			"%s%s%s = GetNode<%s>(\"%s\");" % [
				tabulation,
				tabulation,
				var_name,
				node.get_class(),
				root_node.get_path_to(node)
		])

	return lines


func insert_missing_signal_connections(lines: PoolStringArray, \
	signal_connections: Dictionary, \
	tabulation: String, \
	insert_index: int \
) -> PoolStringArray:
	var type_map = VargenCsharpConstants.VARIANT_TYPE_MAP
	var keywords = VargenCsharpConstants.RESERVED_KEYWORDS

	for key in signal_connections.keys():
		if signal_connections[key].found:
			continue
		var args = signal_connections[key].signal.args
		var line = PoolStringArray()
		line.resize(2 + args.size())
		line.append("%sprivate void %s(" % [tabulation, key])

		for i in range(args.size()):
			var arg = args[i]

			var type = arg["class_name"]
			if type.empty():
				var type_idx = int(arg["type"])
				type_idx = clamp(type_idx, 0, type_map.size() - 1)
				type = type_map[type_idx]

			var name = arg["name"]
			if keywords.has(name):
				name = "@" + name

			line.append("%s %s%s" % [
					type,
					name,
					", " if i < args.size() - 1 else ""
			])
		line.append(")\n%s{\n%s}\n" % [tabulation, tabulation])
		lines.insert(insert_index, line.join(""))

	return lines
