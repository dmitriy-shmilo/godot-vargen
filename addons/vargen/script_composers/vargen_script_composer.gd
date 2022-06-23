class_name VargenScriptComposer
extends Reference

export(String) var variable_prefix = ""
export(bool) var should_insert_nodes = false
export(bool) var should_insert_signals = false

func insert_onready_nodes(source: String, \
	script: Script, \
	root_node: Node, \
	selected_nodes: Array) -> String:
		return source
