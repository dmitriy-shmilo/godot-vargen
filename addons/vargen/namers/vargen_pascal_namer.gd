class_name VargenPascalNamer
extends VargenNamer

export(bool) var is_lower_case = true

func var_name_from_node_name(node_name: String) -> String:
	var name_len = node_name.length()
	var name_result_array = PoolStringArray()

	name_result_array.resize(name_len * 2)

	var first_word_started = false
	var first_word_ended = false
	var current_case = Case.NONE

	for i in range(node_name.length()):
		var c = node_name[i]

		if separators.has(c):
			if current_case == Case.LOWER or current_case == Case.UPPER:
				first_word_ended = first_word_ended or first_word_started
			current_case = Case.NONE
		elif numbers.has(c):
			if current_case == Case.LOWER or current_case == Case.UPPER:
				first_word_ended = first_word_ended or first_word_started
			current_case = Case.NUMBER
			name_result_array.append(c)
		elif c.to_upper() != c: # lowercase alpha
			if not first_word_ended and not is_lower_case:
				name_result_array.append(c.to_upper())
				current_case = Case.UPPER
			elif first_word_started and current_case == Case.NONE or current_case == Case.NUMBER:
				name_result_array.append(c.to_upper())
				current_case = Case.UPPER
				first_word_ended = true
			else:
				name_result_array.append(c)
				current_case = Case.LOWER
			first_word_started = true
		elif c.to_lower() != c: # uppercase alpha
			first_word_ended = first_word_ended or first_word_started and current_case == Case.LOWER
			if not first_word_ended and is_lower_case:
				name_result_array.append(c.to_lower())
				current_case = Case.LOWER
			else:
				current_case = Case.UPPER
				name_result_array.append(c)
			first_word_started = true

	return name_result_array.join("")
