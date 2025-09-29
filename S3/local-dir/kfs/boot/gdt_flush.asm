global gdt_flush

gdt_flush:
    mov eax, [esp+4]    ; Get the pointer to the GDT
    lgdt [eax]          ; Load the GDT pointer
    
    ; Reload segments
    mov ax, 0x10        ; Kernel data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Far jump to reload CS with kernel code segment
    jmp 0x08:flush_complete
    
flush_complete:
    ret