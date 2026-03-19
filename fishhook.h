#ifndef fishhook_h
#define fishhook_h
#include <stddef.h>
#include <stdint.h>
struct rebind_msg { const char *name; void *replacement; void **replaced; };
int rebind_symbols(struct rebind_msg *rebinds, size_t rebinds_nel);
#endif