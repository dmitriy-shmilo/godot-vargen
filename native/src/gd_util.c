#include "gd_util.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdarg.h>

#define TMP_BUFFER_LEN 256

static godot_gdnative_core_api_struct * api = NULL;

void init_util_api(godot_gdnative_core_api_struct * external_api) {
	api = external_api;
}

void gd_debug(const char * msg, ...) {
	assert(api != NULL);
	va_list args;
	char buffer[TMP_BUFFER_LEN];

	va_start(args, msg);
	vsnprintf(buffer, TMP_BUFFER_LEN, msg, args);
	va_end(args);
	godot_string str;
	api->godot_string_new(&str);
	api->godot_string_parse_utf8(&str, buffer);
	api->godot_print(&str);
	api->godot_string_destroy(&str);
}

const char * godot_variant_to_char(const godot_variant * g_variant) {
	godot_string g_string = api->godot_variant_as_string(g_variant);
	godot_char_string c_string = api->godot_string_utf8(&g_string);
	const char * result = api->godot_char_string_get_data(&c_string);

	api->godot_string_destroy(&g_string);
	api->godot_char_string_destroy(&c_string);
	return result;
}

const char * godot_string_to_char(const godot_string * g_string) {
	godot_char_string c_string = api->godot_string_utf8(g_string);
	const char * result = api->godot_char_string_get_data(&c_string);

	api->godot_char_string_destroy(&c_string);
	return result;
}

godot_variant godot_dictionary_get_by_string(godot_dictionary * dict, const char * c_key) {
		godot_string key;
		godot_variant v_key;
		godot_variant result;

		api->godot_string_new(&key);
		api->godot_string_parse_utf8(&key, c_key);
		api->godot_variant_new_string(&v_key, &key);
		result = api->godot_dictionary_get(dict, &v_key);

		api->godot_variant_destroy(&v_key);
		api->godot_string_destroy(&key);

		return result;
}