ASM=nasm
CC=gcc
CFLAGS=-ffreestanding -m32 -fno-pic
LD=ld
LDFLAGS=-m elf_i386 -s -T linker.ld
BOOT_DIR=src/boot
BOOT_INCLUDE_DIR=$(BOOT_DIR)/include
ASMFLAGS=-I $(BOOT_INCLUDE_DIR) -f bin
KERNEL_DIR=src/kernel
BIN_DIR=build/bin
OBJ_DIR=build/obj
OBJS=$(OBJ_DIR)/entry.o $(patsubst $(KERNEL_DIR)/%.c,$(OBJ_DIR)/%.o,$(wildcard $(KERNEL_DIR)/*.c))

.PHONY: atmos floppy_small boot_stages kernel clean always run debug

## assemble each bootloader stage
BOOT_STAGE_SRCS := $(wildcard $(BOOT_DIR)/boot_stage*.asm)
BOOT_STAGE_BINS := $(patsubst $(BOOT_DIR)/%.asm,$(BIN_DIR)/%.bin,$(BOOT_STAGE_SRCS))
boot_stages: $(BOOT_STAGE_BINS)
$(BIN_DIR)/%.bin: $(BOOT_DIR)/%.asm $(BOOT_INCLUDE_DIR)/*
	$(ASM) $(ASMFLAGS) -o $@ $<

## 1.44MB floppy image
atmos: $(BIN_DIR)/atmos.img

$(BIN_DIR)/atmos.img: floppy_small
	dd if=/dev/zero of=$(BIN_DIR)/atmos.img bs=512 count=2880 status=progress
	dd if=$(BIN_DIR)/floppy_small.img of=$(BIN_DIR)/atmos.img bs=512 conv=notrunc status=progress


## small floppy image
floppy_small: $(BIN_DIR)/floppy_small.img

$(BIN_DIR)/floppy_small.img: boot kernel
	cat $(BIN_DIR)/boot.bin $(BIN_DIR)/kernel.bin > $(BIN_DIR)/floppy_small.img


## concatenate all stages into single boot.bin
boot: $(BIN_DIR)/boot.bin
$(BIN_DIR)/boot.bin: boot_stages
	cat $(BOOT_STAGE_BINS) > $@


## kernel
kernel: $(BIN_DIR)/kernel.bin
$(OBJ_DIR)/%.o: $(KERNEL_DIR)/%.c
	$(CC) -c $(CFLAGS) -o $@ $<
$(OBJ_DIR)/entry.o: $(KERNEL_DIR)/entry.asm
	$(ASM) $(KERNEL_DIR)/entry.asm -f elf32 -o $@
$(BIN_DIR)/kernel.bin: $(OBJS) 
	$(LD) $(LDFLAGS) -o $@ $^


## clean
clean:
	rm -rf $(BIN_DIR)/*
	rm -rf $(OBJ_DIR)/*


## always
always: 
	mkdir -p $(BIN_DIR)
	mkdir -p $(OBJ_DIR)


## run
run: atmos
	qemu-system-i386 -m 256M -drive file=$(BIN_DIR)/atmos.img,if=floppy,index=0,media=disk,format=raw -display gtk


## debug
debug: atmos
	bochs -f bochs_config -q


test: always
	$(CC) $(CC_OPTIONS) $(KERNEL_DIR)/*.c -
