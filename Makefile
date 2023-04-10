ASM=nasm
CC=/home/hugo/opt/cross/bin/i686-elf-gcc
CFLAGS=-ffreestanding -m32 -fno-pic
LD=/home/hugo/opt/cross/bin/i686-elf-ld
LDFLAGS=-s -T linker.ld
BOOT_DIR=src/boot
KERNEL_DIR=src/kernel
BIN_DIR=build/bin
OBJ_DIR=build/obj
OBJS=$(OBJ_DIR)/entry.o $(patsubst $(KERNEL_DIR)/%.c,$(OBJ_DIR)/%.o,$(wildcard $(KERNEL_DIR)/*.c))

.PHONY: atmos floppy_small boot kernel clean always run debug

## 1.44MB floppy image
atmos: $(BIN_DIR)/atmos.img

$(BIN_DIR)/atmos.img: floppy_small
	dd if=/dev/zero of=$(BIN_DIR)/atmos.img bs=512 count=2880
	dd if=$(BIN_DIR)/floppy_small.img of=$(BIN_DIR)/atmos.img bs=512 conv=notrunc


## small floppy image
floppy_small: $(BIN_DIR)/floppy_small.img

$(BIN_DIR)/floppy_small.img: boot kernel
	cat $(BIN_DIR)/boot.bin $(BIN_DIR)/kernel.bin > $(BIN_DIR)/floppy_small.img


## bootloader
boot: $(BIN_DIR)/boot.bin

$(BIN_DIR)/boot.bin: always
	$(ASM) $(BOOT_DIR)/boot.asm -f bin -o $(BIN_DIR)/boot.bin


## kernel
kernel: $(BIN_DIR)/kernel.bin
$(OBJ_DIR)/%.o: $(KERNEL_DIR)/%.c
	$(CC) -c $(CFLAGS) -o $@ $<
$(OBJ_DIR)/entry.o: always
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
	qemu-system-i386 -drive file=$(BIN_DIR)/atmos.img,if=floppy,index=0,media=disk,format=raw -display gtk


## debug
debug: atmos
	bochs -f bochs_config -q


test: always
	$(CC) $(CC_OPTIONS) $(KERNEL_DIR)/*.c -
