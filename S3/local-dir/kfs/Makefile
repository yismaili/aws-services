CC = gcc
AS = nasm
LD = ld

CFLAGS = -m32 -ffreestanding -fno-builtin -fno-exceptions \
	-fno-stack-protector -nostdlib -nodefaultlibs \
	-Wall -Wextra -Ikernel/include

ASFLAGS = -f elf32
LDFLAGS = -m elf_i386 -T linker.ld

BOOTDIR = boot
KERNELDIR = kernel
LIBDIR = $(KERNELDIR)/lib
OBJDIR = obj
ISODIR = iso

# Source files
ASM_SOURCES = $(BOOTDIR)/bootloader_entry.asm $(BOOTDIR)/gdt_flush.asm
C_SOURCES = $(KERNELDIR)/kernel_main.c $(KERNELDIR)/vga_screen.c $(KERNELDIR)/gdt.c

# Object files
ASM_OBJECTS = $(ASM_SOURCES:$(BOOTDIR)/%.asm=$(OBJDIR)/%.o)
C_OBJECTS = $(C_SOURCES:$(KERNELDIR)/%.c=$(OBJDIR)/kernel_%.o)

ALL_OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)

KERNEL = kernel.bin
ISO = kernel.iso

.PHONY: all
all: $(KERNEL)

$(KERNEL): $(ALL_OBJECTS) linker.ld
	@echo "Linking kernel..."
	$(LD) $(LDFLAGS) -o $@ $(ALL_OBJECTS)
	@echo "Kernel built successfully!"

$(OBJDIR)/%.o: $(BOOTDIR)/%.asm | $(OBJDIR)
	@echo "Assembling $<..."
	$(AS) $(ASFLAGS) $< -o $@

$(OBJDIR)/kernel_%.o: $(KERNELDIR)/%.c | $(OBJDIR)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/lib_%.o: $(LIBDIR)/%.c | $(OBJDIR)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR):
	mkdir -p $(OBJDIR)

.PHONY: iso
iso: $(KERNEL) $(ISODIR)/boot/grub/grub.cfg
	@echo "Creating bootable ISO..."
	cp $(KERNEL) $(ISODIR)/boot/
	grub-mkrescue -o $(ISO) $(ISODIR)
	@echo "ISO created: $(ISO)"

$(ISODIR)/boot/grub/grub.cfg: grub.cfg
	mkdir -p $(ISODIR)/boot/grub
	cp grub.cfg $(ISODIR)/boot/grub/

.PHONY: test
test: $(ISO)
	@echo "Starting QEMU (emulation mode)..."
	qemu-system-i386 -cdrom $(ISO) -m 512M

.PHONY: test-kvm
test-kvm: $(ISO)
	@echo "Starting QEMU with KVM acceleration..."
	qemu-system-i386 -cdrom $(ISO) -enable-kvm -m 512M

.PHONY: clean
clean:
	@echo "Cleaning..."
	rm -rf $(OBJDIR) $(KERNEL) $(ISO) $(ISODIR)
	@echo "Clean complete."

.PHONY: debug
debug: $(ISO)
	@echo "Starting QEMU with debugging..."
	qemu-system-i386 -cdrom $(ISO) -m 512M -s -S

.PHONY: info
info: $(KERNEL)
	@echo "Kernel Information:"
	@echo "=================="
	@echo "Size: $$(du -h $(KERNEL) | cut -f1)"
	@echo "Type: $$(file $(KERNEL))"
	@echo ""
	@objdump -h $(KERNEL)
	@echo ""
	@echo "GDT Section:"
	@objdump -s -j .gdt_section $(KERNEL) 2>/dev/null || echo "GDT section not found"

.PHONY: help
help:
	@echo "KFS_2 Kernel Build System"
	@echo "========================="
	@echo "Build targets:"
	@echo "  all         - Build kernel binary (default)"
	@echo "  iso         - Create bootable ISO image"
	@echo "  clean       - Remove build files"
	@echo ""
	@echo "Testing targets:"
	@echo "  test        - Test with QEMU (pure emulation)"
	@echo "  test-kvm    - Test with QEMU + KVM"
	@echo "  debug       - Start QEMU with GDB debugging"
	@echo "  info        - Show kernel information"
	@echo "  help        - Show this help"