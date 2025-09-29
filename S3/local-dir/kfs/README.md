    https://www.thejat.in/learn/the-bootloader-multiboot


    https://medium.com/@ankitkpandey1/creating-your-own-kernel-part-1-genesis-8cabad8dc448



    https://dev.to/frosnerd/writing-my-own-boot-loader-3mld


                Power On
                    ↓
        BIOS (checks hardware, finds bootloader)
                    ↓
        GRUB (loads kernel into memory)
                    ↓
        Kernel starts (still Real Mode)
                    ↓
        Kernel builds GDT (table with memory rules)
                    ↓
        CPU loads GDT + switch to Protected Mode
                    ↓
        Kernel sets up stack
                    ↓
        Operating System is alive ✅
