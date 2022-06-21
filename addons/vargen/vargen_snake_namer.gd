class_name VargenSnakeNamer
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
	var name_len = node_name.length()
	var name_result_array = PoolStringArray()

	name_result_array.resize(name_len * 2)

	var is_upper = node_name[0].to_lower() != node_name[0]
	var skip_split = false

	var current_case = Case.NONE

	for i in range(node_name.length()):
		var c = node_name[i]

		if separators.has(c):
			current_case = Case.NONE
		elif numbers.has(c):
			if current_case == Case.LOWER or current_case == Case.UPPER:
				name_result_array.append("_")
			current_case = Case.NUMBER
		elif c.to_lower() == c:
			current_case = Case.LOWER
		else:
			if current_case == Case.LOWER:
				name_result_array.append("_")
			current_case = Case.UPPER

		name_result_array.append(c.to_lower())

	return name_result_array.join("")

func var_name_from_node(node: Node) -> String:
	return var_name_from_node_name(node.name)
