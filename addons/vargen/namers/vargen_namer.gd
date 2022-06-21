class_name VargenNamer
extends Reference

enum Case {
	NONE,
	NUMBER,
	UPPER,
	LOWER
}


export(Array, String) var separators = ["_"]
export(Array, String) var numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]


func var_name_from_node_name(node_name: String) -> String:
	return node_name


func var_name_from_node(node: Node) -> String:
	return var_name_from_node_name(node.name)
