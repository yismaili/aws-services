#include "../include/kernel.h"

int kfs_strlen(char *str)
{
    int len = 0;
    if (str[0] == 0)
        return 0;
    while (str[len]){
        len++;
    }
    return len;
}