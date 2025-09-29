#include "include/kernel.h"

unsigned int _cursor_x = 0;
unsigned int _cursor_y = 0;
vga_entry* _vga_buffer = (vga_entry*)VGA_MEMORY;
char _current_color = 0x07;

void _screen_puts(char *str){
    int i = 0;
    while (str[i] != '\0')
    {
        _screen_putchar(str[i]);
        i++;
    }
}

void _screen_putchar(char c){
    if (c == '\n'){
        _cursor_x = 0;
        _cursor_y++;
    }
    else if (c == '\r'){
        _cursor_x = 0;
    }else if (c == '\t'){
        _cursor_x = (_cursor_x + 8) & ~(8 - 1);
    }else if (c == '\b' && _cursor_x > 0){
        _cursor_x--;
    }
    else{
        const uint32_t index = _cursor_y * VGA_WIDTH + _cursor_x;
        
        _vga_buffer[index].character = c;
        _vga_buffer[index].attribute = _current_color;
        _cursor_x++;
    }

    if (_cursor_x >= VGA_WIDTH) { //Handle line wrapping
        _cursor_x = 0;
        _cursor_y++;
    }

    if (_cursor_y >= VGA_HEIGHT) {   //Handle screen scrolling 
        _screen_scroll();
        _cursor_y = VGA_HEIGHT - 1;
    }
    _screen_update();
}

void _screen_update(){
    unsigned int position = _cursor_y * VGA_WIDTH + _cursor_x;

    // set cursor low byte
    __asm__ volatile ("outb %%al, %%dx" : : "a"(0x0F), "d"(0x3D4));
    __asm__ volatile ("outb %%al, %%dx" : : "a"((uint8_t)(position & 0xFF)), "d"(0x3D5));
    
    // set cursor high byte  
    __asm__ volatile ("outb %%al, %%dx" : : "a"(0x0E), "d"(0x3D4));
    __asm__ volatile ("outb %%al, %%dx" : : "a"((uint8_t)((position >> 8) & 0xFF)), "d"(0x3D5));
}

int8_t _vga_color(uint8_t fg, uint8_t bg) 
{
    return fg | (bg << 4);
}

void _screen_clear() {
    const vga_entry blank = {
        .character = ' ',
        .attribute = _current_color
    };
    
    uint32_t i = 0;
    while (i < VGA_SIZE) {
        _vga_buffer[i] = blank;
        i++;
    }
    
    _cursor_x = 0;
    _cursor_y = 0;
    _screen_update();
}

void _screen_scroll(void) {

    const vga_entry blank = {
        .character = ' ',
        .attribute = _current_color
    };
    
    
    uint32_t i = 0;
    while (i < (VGA_HEIGHT - 1) * VGA_WIDTH) { // Move all lines up 
        _vga_buffer[i] = _vga_buffer[i + VGA_WIDTH];
        i++;
    }

  // Clear last line
    i = (VGA_HEIGHT - 1) * VGA_WIDTH; 
    while (i < VGA_SIZE) {
        _vga_buffer[i] = blank;
        i++;
    }
}