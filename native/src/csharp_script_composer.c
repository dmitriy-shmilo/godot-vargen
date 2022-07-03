#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <assert.h>
#include <wchar.h>
#include "gdnative_api_struct.gen.h"

const godot_gdnative_core_api_struct * api = NULL;
const godot_gdnative_ext_nativescript_api_struct * nativescript_api = NULL;

typedef struct self_fields {
	unsigned int original_line_count;
} self_fields;


GDCALLINGCONV void * constructor(godot_object * instance, void * method_data);
GDCALLINGCONV void destructor(godot_object * instance, void * method_data, void * user_data);
GDCALLINGCONV godot_variant composer_compose(godot_object * instance, void * method_data, void * user_data,
	int num_args, void ** args);

void gd_debug(const char * msg, ...) {
	assert(api != NULL);
	va_list args;
	char buffer[256];

	va_start(args, msg);
	vsnprintf(buffer, 256, msg, args);
	va_end(args);
	godot_string str;
	api->godot_string_new(&str);
	api->godot_string_parse_utf8(&str, buffer);
	api->godot_print(&str);
	api->godot_string_destroy(&str);
}

#ifdef DEBUG
#define LOG_D(fmt, args...) gd_debug(fmt, ##args)
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
	return fields;
}

void destructor(godot_object * instance, void * method_data, void * user_data) {
	LOG_D("destructor");
	api->godot_free(user_data);
}

godot_variant composer_compose(godot_object * instance, void * method_data, void * user_data,
	int num_args, void ** args) {
	LOG_D("composer_compose with %d args", num_args);

	for (int i = 0; i < num_args; i++) {
		void * var_arg = args[i];
		godot_variant_type var_type = api->godot_variant_get_type(var_arg);
		LOG_D("composer_compose var#%d type: %d", i, var_type);
	}

	char buffer[256];
	godot_string path = api->godot_variant_as_string(args[0]);
	const wchar_t * w_path = api->godot_string_wide_str(&path);
	wcstombs(buffer, w_path, 256);

	FILE * file = fopen(buffer, "r");

	while(fgets(buffer, 256, file)) {
		LOG_D(buffer);
	}

	godot_string data;
	godot_variant ret;

	return ret;
}
