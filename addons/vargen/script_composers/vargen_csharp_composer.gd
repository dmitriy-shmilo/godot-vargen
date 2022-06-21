class_name VargenCSharpComposer
extends VargenScriptComposer

func insert_onready_nodes(source: String, \
	script: Script, \
	root_node: Node, \
	selected_nodes: Array) -> String:

	var tabulation = ""
	var lines = source.split("\n")
	var top_class_index = -1
	var ready_method_index = -1
	var namer = VargenPascalNamer.new()

	for i in range(lines.size()):
		var line = lines[i] as String
		var tab_before_index = -1
		if top_class_index < 0 and "public class %s" % [script.resource_name] in line:
			top_class_index = i + 2 # assuming open bracket is next
		elif ready_method_index < 0:
			tab_before_index = line.find("public override void _Ready()")
			if tab_before_index >= 0:
				ready_method_index = i + 2 # assuming open bracket is next
				tabulation = line.substr(0, tab_before_index)

		if top_class_index >= 0 and ready_method_index >= 0:
			break

	# TODO: return an error instead of printing
	if top_class_index < 0:
		printerr("Can't find class %s in %s." % [script.resource_name, script.resource_path])
		return source

	if ready_method_index < 0:
		printerr("Can't find _Ready method in %s." % [script.resource_path])
		return source

	for i in range(selected_nodes.size()):
		var node = selected_nodes[i] as Node
		var var_name = variable_prefix + namer.var_name_from_node(node)
		lines.insert(top_class_index + i, \
			"%sprivate %s %s = null;" % [
				tabulation,
				node.get_class(),
				var_name
		])
		lines.insert(ready_method_index + i * 2 + 1, \
			"%s%s%s = GetNode<%s>(\"%s\");" % [
				tabulation,
				tabulation,
				var_name,
				node.get_class(),
				root_node.get_path_to(node)
		])
	return lines.join("\n")
