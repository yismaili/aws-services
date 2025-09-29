#include "include/kernel.h"
#include "include/gdt.h"

void kernel_main() {
    // Initialize VGA display
    _current_color = _vga_color(VGA_LIGHT_GREY, VGA_BLACK);
    _screen_clear();
    
    _screen_puts("KFS_2 - GDT & Stack Implementation\n");
    _screen_puts("==================================\n\n");
    
    // Initialize GDT
    _screen_puts("Initializing GDT...\n");
    gdt_init();
    
    _screen_puts("\nGDT Segments:\n");
    _screen_puts("- Kernel Code: 0x08\n");
    _screen_puts("- Kernel Data: 0x10\n");
    _screen_puts("- Kernel Stack: 0x18\n");
    _screen_puts("- User Code: 0x20\n");
    _screen_puts("- User Data: 0x28\n");
    _screen_puts("- User Stack: 0x30\n\n");
    
    // test stack printing
    _screen_puts("Printing stack information:\n");
    print_stack_info();
    
    _screen_puts("\nKernel initialization complete!\n");
    _screen_puts("System ready for operation.\n");
    
    // Infinite loop
    while (1) {
        __asm__ volatile ("hlt");
    }
}