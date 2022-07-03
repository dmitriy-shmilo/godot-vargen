#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <assert.h>
#include <wchar.h>

#include "gdnative_api_struct.gen.h"

#define TMP_BUFFER_LEN 256

const godot_gdnative_core_api_struct * api = NULL;
const godot_gdnative_ext_nativescript_api_struct * nativescript_api = NULL;

typedef struct self_fields {
	size_t original_line_count;
} self_fields;

typedef struct {
	size_t index;
	char * line;
	size_t line_len;
} insertion;

GDCALLINGCONV void * constructor(godot_object * instance, void * method_data);
GDCALLINGCONV void destructor(godot_object * instance, void * method_data, void * user_data);
GDCALLINGCONV godot_variant composer_compose(godot_object * instance, void * method_data, void * user_data,
	int num_args, godot_variant ** args);

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

#ifdef DEBUG
#define LOG_D(...) gd_debug(__VA_ARGS__);
#else
#define LOG_D(...)
#endif


void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options * options) {
	api = options->api_struct;

	for (int i = 0; i < api->num_extensions; i++) {
		switch (api->extensions[i]->type) {
			case GDNATIVE_EXT_NATIVESCRIPT:
				nativescript_api = api->extensions[i];
				break;
		}
	}
	LOG_D("godot_gdnative_init");
}


void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options * options) {
	LOG_D("godot_gdnative_terminate");
	api = NULL;
	nativescript_api = NULL;
}


void GDN_EXPORT godot_nativescript_init(void * handle) {
	LOG_D("godot_nativescript_init");
	if (nativescript_api == NULL) {
		return;
	}

	godot_instance_create_func create = {
		.create_func = &constructor
	};

	godot_instance_destroy_func destroy = {
		.destroy_func = &destructor
	};

	nativescript_api->godot_nativescript_register_class(
		handle, "CSharpScriptComposer", "Reference",
		create, destroy);

	godot_instance_method compose = {
		.method = composer_compose
	};

	godot_method_attributes attr = {
		GODOT_METHOD_RPC_MODE_DISABLED
	};

	nativescript_api->godot_nativescript_register_method(
		handle, "CSharpScriptComposer", "compose",
		attr, compose);
}


void * constructor(godot_object * instance, void * method_data) {
	LOG_D("constructor");
	self_fields * fields = api->godot_alloc(sizeof(self_fields));
	memset(fields, 0, sizeof(self_fields));
	return fields;
}

void destructor(godot_object * instance, void * method_data, void * user_data) {
	LOG_D("destructor");
	api->godot_free(user_data);
}

#define CHECK_ARG(args, index, type, error_msg) \
if (api->godot_variant_get_type(args[index]) != type) { \
		api->godot_print_error(error_msg, "", __FILE__, __LINE__); \
		return ret; \
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

godot_variant composer_compose(
	godot_object * instance, void * method_data, void * user_data,
	int num_args, godot_variant ** args) {
	godot_variant ret; 
	api->godot_variant_new_nil(&ret);

	LOG_D("composer_compose with %d args", num_args);

	#if DEBUG
	for (int i = 0; i < num_args; i++) {
		void * var_arg = args[i];
		godot_variant_type var_type = api->godot_variant_get_type(var_arg);
		LOG_D("composer_compose arg#%d type: %d", i, var_type);
	}
	#endif

	if (num_args != 4) {
		api->godot_print_error("CSharpScriptComposer.compose expected 4 arguments", "", __FILE__, __LINE__);
		return ret;
	}

	CHECK_ARG(args, 0, GODOT_VARIANT_TYPE_STRING, "First argument is expected to be a string")
	CHECK_ARG(args, 1, GODOT_VARIANT_TYPE_STRING, "Second argument is expected to be a string")
	CHECK_ARG(args, 2, GODOT_VARIANT_TYPE_ARRAY, "Third argument is expected to be an array")
	CHECK_ARG(args, 3, GODOT_VARIANT_TYPE_ARRAY, "Fourth argument is expected to be an array")

	// these are allocated dynamically and need to be freed
	char * original_file_location = NULL;
	char * tmp_file_location = NULL;
	char * class_start_line = NULL;
	char * class_end_line = NULL;

	self_fields * fields = (self_fields *)user_data;
	char tmp_buffer[TMP_BUFFER_LEN];

	char tab[5] = { 0 };
	size_t tab_len = 5;
	size_t class_top_index = 0;
	size_t ready_method_index = 0;
	size_t class_bottom_index = 0;


	const char * c_tmp = godot_variant_to_char(args[1]);
	class_start_line = api->godot_alloc(strlen(c_tmp) + 14);
	strcpy(class_start_line, "public class ");
	strcat(class_start_line, c_tmp);

	c_tmp = godot_variant_to_char(args[0]);
	original_file_location = api->godot_alloc(strlen(c_tmp) + 1);
	tmp_file_location = api->godot_alloc(strlen(c_tmp) + 8);
	strcpy(original_file_location, c_tmp);
	strcpy(tmp_file_location, c_tmp);
	strcat(tmp_file_location, ".vargen");

	godot_array node_refs = api->godot_variant_as_array(args[2]);
	godot_int node_refs_count = api->godot_array_size(&node_refs);
	LOG_D("%d node references will be processed", node_refs_count)

	godot_array signal_refs = api->godot_variant_as_array(args[3]);
	godot_int signal_refs_count = api->godot_array_size(&signal_refs);
	LOG_D("%d signal references will be processed", signal_refs_count)

	size_t insertions_capacity = 0;
	size_t insertions_count = 0;
	insertion * insertions;
	// 2 lines will be inserted per node ref
	insertions_capacity = node_refs_count * 2 + signal_refs_count;
	insertions = api->godot_alloc(insertions_capacity * sizeof(insertion));

	FILE * file = fopen(original_file_location, "r");

	// TODO: handle lines longer than TMP_BUFFER_LEN
	for(size_t i = 0; fgets(tmp_buffer, TMP_BUFFER_LEN, file); i++) {
		if (tab[0] == '\0') {
			if (tmp_buffer[0] == '\t') {
				tab[0] = '\t';
			} else if (tmp_buffer[0] == ' ') {
				// TODO: don't assume tab length in spaces
				tab[0] = ' ';
				tab[1] = ' ';
				tab[2] = ' ';
				tab[3] = ' ';
			}

			if (tab[0] != '\0') {
				class_end_line = api->godot_alloc(tab_len + 2);
				strcpy(class_end_line, tab);
				strcat(class_end_line, "}");
			}
		}

		if (ready_method_index == 0 && strstr(tmp_buffer, "public override void _Ready()") != NULL) {
			ready_method_index = i + 2;
		}

		if (class_top_index == 0 && strstr(tmp_buffer, class_start_line) != NULL) {
			class_top_index = i + 2;
		}

		if (class_end_line != NULL && strstr(tmp_buffer, class_end_line) != NULL) {
			class_bottom_index = i;
		}

		fields->original_line_count += 1;
	}

	for (int i = 0; i < node_refs_count; i++) {
		godot_variant v_dict = api->godot_array_get(&node_refs, i);
		godot_dictionary dict = api->godot_variant_as_dictionary(&v_dict);

		godot_variant v_type = godot_dictionary_get_by_string(&dict, "type");
		godot_string type = api->godot_variant_as_string(&v_type);
		godot_variant v_path = godot_dictionary_get_by_string(&dict, "path");
		godot_string path = api->godot_variant_as_string(&v_path);
		godot_variant v_name = godot_dictionary_get_by_string(&dict, "name");
		godot_string name = api->godot_variant_as_string(&v_name);

		const char * c_type = godot_string_to_char(&type);
		const char * c_path = godot_string_to_char(&path);
		const char * c_name = godot_string_to_char(&name);

		insertion decl = { 0 };
		decl.line_len = 18 + tab_len + strlen(c_name);
		decl.index = class_top_index;
		decl.line = api->godot_alloc(decl.line_len);
		snprintf(decl.line, decl.line_len, "%sprivate %s = null;\n", tab, c_name);
		insertions[insertions_count] = decl;
		insertions_count += 1;

		insertion init = { 0 };
		init.line_len = 19 + tab_len * 2 + strlen(c_path) + strlen(c_name) + strlen(c_type);
		init.index = ready_method_index;
		init.line = api->godot_alloc(init.line_len);
		snprintf(init.line, init.line_len, "%s%s%s = GetNode<%s>(\"%s\");\n", tab, tab, c_name, c_type, c_path);
		insertions[insertions_count] = init;
		insertions_count += 1;

		api->godot_variant_destroy(&v_type);
		api->godot_string_destroy(&type);
		api->godot_variant_destroy(&v_path);
		api->godot_string_destroy(&path);
		api->godot_variant_destroy(&v_name);
		api->godot_string_destroy(&name);
		api->godot_variant_destroy(&v_dict);
		api->godot_dictionary_destroy(&dict);
	}

	LOG_D("Class top found at %d", class_top_index);
	LOG_D("Ready method found at %d", ready_method_index);
	LOG_D("Class bottom found at %d", class_bottom_index);

	fseek(file, 0, SEEK_SET);

	FILE * tmp_file = fopen(tmp_file_location, "w");
	for(size_t i = 0, j = 0; fgets(tmp_buffer, TMP_BUFFER_LEN, file); i++) {

		while (j < insertions_count && insertions[j].index <= i) {
			LOG_D("Inserting %s", insertions[j].line);
			fputs(insertions[j].line, tmp_file);

			api->godot_free(insertions[j].line);
			j++;
		}
		fputs(tmp_buffer, tmp_file);
	}

	fclose(tmp_file);
	fclose(file);

	LOG_D("Total lines read: %d", fields->original_line_count);
	LOG_D("Total insertions: %d (out of %d capacity)", insertions_count, insertions_capacity);

	api->godot_array_destroy(&node_refs);
	api->godot_array_destroy(&signal_refs);

	api->godot_free(class_start_line);
	api->godot_free(class_end_line);
	api->godot_free(original_file_location);
	api->godot_free(tmp_file_location);
	api->godot_free(insertions);

	return ret;
}
