MAGIC       equ 0x1BADB002  ; multiboot header     
FLAGS       equ 0x00000003
CHECKSUM    equ -(MAGIC + FLAGS)

section .multiboot ; multiboot header section
align 4
    dd MAGIC
    dd FLAGS
    dd CHECKSUM

section .bss  ;reserve stack space
align 16
stack_bottom:
    resb 16384 
stack_top:

section .text ; code section start
global _start
extern kernel_main

_start:
    mov esp, stack_top ; setup the stack
    
    push 0 ; clean old flags
    popf
    
    call kernel_main
    
    cli ; loop 
.hang:
    hlt
    jmp .hang