#include "../include/kernel.h"

char* kfs_strcpy(char* dest, const char* src)
{
    char* original_ptr = dest;
    int i = 0;
    while (src[i]) {
        dest[i] = src[i];
        i++;
    }
    dest[i] = '\0'; 
    return original_ptr;
}
