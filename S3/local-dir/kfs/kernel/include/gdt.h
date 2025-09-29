#ifndef GDT_H
#define GDT_H

#include "types.h"

#define GDT_ENTRIES 6

// GDT entry structure
typedef struct __attribute__((packed)) {
    uint16_t limit_low;      // Lower 16 bits of limit
    uint16_t base_low;       // Lower 16 bits of base
    uint8_t  base_middle;    // Next 8 bits of base
    uint8_t  access;         // Access flags
    uint8_t  granularity;    // Granularity and upper 4 bits of limit
    uint8_t  base_high;      // Upper 8 bits of base
} gdt_entry_t;

// GDT pointer structure
typedef struct __attribute__((packed)) {
    uint16_t limit;          // Size of GDT - 1
    uint32_t base;           // Address of GDT
} gdt_ptr_t;

// Access byte flags
#define GDT_PRESENT     0x80    // Present bit
#define GDT_PRIVL0      0x00    // Ring 0 (kernel)
#define GDT_PRIVL3      0x60    // Ring 3 (user)
#define GDT_EXEC_READ   0x1A    // Executable, readable
#define GDT_DATA_WRITE  0x12    // Data, writable

// Granularity flags
#define GDT_GRANULARITY 0xC0    // 4KB granularity, 32-bit
#define GDT_SIZE_32     0x40    // 32-bit segment

void gdt_init(void);
void gdt_set_gate_temp(int num, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran);
void gdt_flush(uint32_t gdt_ptr);

#endif
