tool
extends EditorScript

func _run():
	for m in get_method_list():
		if m.name.begins_with("_test"):
			print_debug("Executing ", m.name)
			call(m.name)


func _name_and_assert(input: String, expected_result: String) -> void:
	var namer = VargenSnakeNamer.new()
	var result = namer.var_name_from_node_name(input)
	assert(result == expected_result, \
		"Expected '%s', but got '%s' from '%s'." \
			% [expected_result, result, input])


func _test_one_word_lower_case() -> void:
	_name_and_assert("foo", "foo")


func _test_two_words_snake_lower_case() -> void:
	_name_and_assert("foo_bar", "foo_bar")


func _test_one_word_upper_case() -> void:
	_name_and_assert("FOO", "foo")


func _test_two_words_snake_upper_case() -> void:
	_name_and_assert("FOO_BAR", "foo_bar")


func _test_one_word_pascal_case() -> void:
	_name_and_assert("Foo", "foo")


func _test_two_words_pascal_case() -> void:
	_name_and_assert("FooBar", "foo_bar")


func _test_two_words_pascal_case_abbr() -> void:
	_name_and_assert("FooBAR", "foo_bar")


func _test_non_ascii_lower_case() -> void:
	_name_and_assert("бар", "бар")


func _test_non_ascii_upper_case() -> void:
	_name_and_assert("БАР", "бар")


func _test_separating_number_lower_case() -> void:
	_name_and_assert("foo1bar", "foo_1bar")


func _test_separating_number_upper_case() -> void:
	_name_and_assert("FOO1BAR", "foo_1bar")


func _test_separating_number_lower_then_upper_case() -> void:
	_name_and_assert("foo1BAR", "foo_1bar")


func _test_separating_number_upper_then_lower_case() -> void:
	_name_and_assert("foo1BAR", "foo_1bar")


func _test_multiple_numbers() -> void:
	_name_and_assert("foo123", "foo_123")


func _test_starting_number() -> void:
	_name_and_assert("1foo", "1foo")
