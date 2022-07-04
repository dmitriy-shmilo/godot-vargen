#pragma once
#include "gdnative_api_struct.gen.h"

#ifdef DEBUG
#define LOG_D(...) gd_debug(__VA_ARGS__);
#else
#define LOG_D(...)
#endif

#define LOG_E(function, ...) gd_error(__FILE__, __LINE__, function, __VA_ARGS__);
#define LOG_W(function, ...) gd_warn(__FILE__, __LINE__, function, __VA_ARGS__);

void init_util_api(godot_gdnative_core_api_struct * external_api);
void gd_debug(const char * msg, ...);
void gd_error(const char * file, int line, const char * function, const char * msg, ...);
void gd_warn(const char * file, int line, const char * function, const char * msg, ...);
const char * godot_variant_to_char(const godot_variant * g_variant);
const char * godot_string_to_char(const godot_string * g_string);
godot_variant godot_dictionary_get_by_string(godot_dictionary * dict, const char * c_key);