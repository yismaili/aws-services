#include "include/gdt.h"
#include "include/kernel.h"


/* 
The Global Descriptor Table (GDT) is a special table that the CPU uses to understand memory layout
 */

    /*
    It tells the CPU:

    Where a segment of memory starts (base address)

    How big it is (limit/size)

    What kind of access is allowed (permissions)
*/


/*
Typical entries are:

    Kernel Code Segment – where kernel instructions live.

    Kernel Data Segment – where kernel variables are stored.

    Kernel Stack – memory space for function calls and returns in kernel.

    User Code Segment – program instructions in user mode.

    User Data Segment – program variables in user mode.

    User Stack – stack space for user programs.
*/
// GDT entries array at fixed address
static gdt_entry_t gdt_entries[GDT_ENTRIES] __attribute__((section(".gdt_section")));
static gdt_ptr_t gdt_ptr;

// Initialize the GDT
void gdt_init(void) {
    // Set up the GDT pointer
    gdt_ptr.limit = (sizeof(gdt_entry_t) * GDT_ENTRIES) - 1;
    gdt_ptr.base = (uint32_t)&gdt_entries;
    
    // Set up GDT entries
    gdt_set_gate(0, 0, 0, 0, 0);                // Null segmentit required by cpu
    
    /*
        Entry 1 = Kernel Code segment.
        Base = 0 (starts at address 0).
        Limit = 0xFFFFFFFF (4 GB, max memory).
        Access = present, privilege 0 (kernel), executable.
        Granularity = 4KB pages, 32-bit mode.
    */
    // Kernel segments
    gdt_set_gate(1, 0, 0xFFFFFFFF,              // Kernel code
                 GDT_PRESENT | GDT_PRIVL0 | GDT_EXEC_READ,
                 GDT_GRANULARITY | GDT_SIZE_32);

    /*
        Entry 2 = Kernel Data segment.
    */   
    gdt_set_gate(2, 0, 0xFFFFFFFF,              // Kernel data
                 GDT_PRESENT | GDT_PRIVL0 | GDT_DATA_WRITE,
                 GDT_GRANULARITY | GDT_SIZE_32);

    /*
        Entry 3 = Kernel Stack segment.
    */      
    gdt_set_gate(3, 0, 0xFFFFFFFF,              // Kernel stack
                 GDT_PRESENT | GDT_PRIVL0 | GDT_DATA_WRITE,
                 GDT_GRANULARITY | GDT_SIZE_32);
    /*
        Entry 4 = User Code segment.
        Privilege = 3 (user mode).
        Executable, readable.
    */
    // User segments
    gdt_set_gate(4, 0, 0xFFFFFFFF,              // User code
                 GDT_PRESENT | GDT_PRIVL3 | GDT_EXEC_READ,
                 GDT_GRANULARITY | GDT_SIZE_32);

    /*
        Entry 5 = User Data/Stack segment.
        Privilege = 3 (user mode).
        Read/write allowed.
    */          
    gdt_set_gate(5, 0, 0xFFFFFFFF,              // User data/stack
                 GDT_PRESENT | GDT_PRIVL3 | GDT_DATA_WRITE,
                 GDT_GRANULARITY | GDT_SIZE_32);
    
    // Load the GDT This calls an assembly function that runs lgdt [gdt_ptr].
    gdt_flush((uint32_t)&gdt_ptr); // After this, the CPU officially uses your GDT.
    
    _screen_puts("GDT initialized successfully!\n");
}

// Set a GDT gate
void gdt_set_gate(int num, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran) {
    /* 
        base_low → lowest 16 bits (bits 0–15)

        base_middle → middle 8 bits (bits 16–23)

        base_high → highest 8 bits (bits 24–31)
    */
    // ---> The base tells the CPU where the segment starts in memory
    gdt_entries[num].base_low = (base & 0xFFFF);
    gdt_entries[num].base_middle = (base >> 16) & 0xFF;
    gdt_entries[num].base_high = (base >> 24) & 0xFF;
    
    /*
        It also gets split into 2 parts:

        limit_low → lowest 16 bits

        The top 4 bits go inside granularity    
    */
    // ---> The limit tells the CPU how big the segment is
    gdt_entries[num].limit_low = (limit & 0xFFFF);
    gdt_entries[num].granularity = (limit >> 16) & 0x0F;
     /*
    The granularity byte is special:

        Top 4 bits = come from the limit
        Bottom 4 bits = come from gran flags (like 4KB vs 1B, 16-bit vs 32-bit mode)
    */
    // the purpose of gran is to control memory segment size and mode (16-bit, 32-bit, 64-bit, byte vs 4K granularity)
    gdt_entries[num].granularity |= gran & 0xF0; //The granularity field in a GDT entry controls how the CPU interprets the segment limit and also some mode settings.
    /*
        Set the access byte
            Is the segment present?

            Is it code or data?

            Is it kernel (ring 0) or user (ring 3)?

            Is it executable or writable?
    */
    gdt_entries[num].access = access;
}

// Stack management functions
void print_stack_info(void) {
    uint32_t esp, ebp;
    
    // Get current stack and base pointers
    __asm__ volatile ("mov %%esp, %0" : "=r"(esp));
    __asm__ volatile ("mov %%ebp, %0" : "=r"(ebp));
    
    _screen_puts("=== KERNEL STACK INFO ===\n");
    _screen_puts("Stack Pointer (ESP): 0x");
    print_hex(esp);
    _screen_putchar('\n');
    
    _screen_puts("Base Pointer (EBP): 0x");
    print_hex(ebp);
    _screen_putchar('\n');
    
    // Print stack contents (last 16 entries)
    _screen_puts("\n--- Stack Contents ---\n");
    uint32_t* stack_ptr = (uint32_t*)esp;
    int i = 0;
    while (i < 16) {
        _screen_puts("0x");
        print_hex((uint32_t)(stack_ptr + i));
        _screen_puts(": 0x");
        print_hex(stack_ptr[i]);
        _screen_putchar('\n');
        i++;
    }
    
    _screen_puts("========================\n");
}

// Helper function to print hexadecimal values
void print_hex(uint32_t value) {
    char hex_chars[] = "0123456789ABCDEF";
    char buffer[9];
    buffer[8] = '\0';
    int i = 7;
    
    while(i >= 0) {
        buffer[i--] = hex_chars[value & 0xF];
        value >>= 4;
    }
    
    _screen_puts(buffer);
}

// Enhanced printk function
void printk(const char* format, ...) {
    _screen_puts((char*)format);
}
