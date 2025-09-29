#ifndef KERNEL_H
#define KERNEL_H

#include "types.h"

#define VGA_MEMORY 0xB8000
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_SIZE (VGA_WIDTH * VGA_HEIGHT)

typedef struct __attribute__((packed)) vga_entry {
    char character;
    char attribute;
} vga_entry;

// Global variables
extern unsigned int _cursor_x;
extern unsigned int _cursor_y;
extern vga_entry* _vga_buffer;
extern char _current_color;

// VGA Screen functions
void _screen_putchar(char c);
void _screen_puts(char* str);
void _screen_update();
void _screen_clear();
int8_t _vga_color(uint8_t fg, uint8_t bg);
void _screen_scroll(void);

// String functions
int kfs_strcmp(const char* s1, const char* s2);
char* kfs_strcpy(char* dest, const char* src);
int kfs_strlen(char *str);

// Stack and debugging functions
void print_stack_info(void);
void print_hex(uint32_t value);
void printk(const char* format, ...);

#endif