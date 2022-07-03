#pragma once
#include "gdnative_api_struct.gen.h"

#ifdef DEBUG
#define LOG_D(...) gd_debug(__VA_ARGS__);
#else
#define LOG_D(...)
#endif

void init_util_api(godot_gdnative_core_api_struct * external_api);
void gd_debug(const char * msg, ...);
const char * godot_variant_to_char(const godot_variant * g_variant);
const char * godot_string_to_char(const godot_string * g_string);
godot_variant godot_dictionary_get_by_string(godot_dictionary * dict, const char * c_key);