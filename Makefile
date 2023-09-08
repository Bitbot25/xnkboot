NASM=nasm

ASM_SRC=asm
QEMU=qemu-system-x86_64
BUILD_DIR=build
IMG_FILE=$(BUILD_DIR)/boot.img

all: clean build

qemu: $(IMG_FILE)
	$(QEMU) -drive format=raw,file=$(IMG_FILE)

build: setup $(IMG_FILE)

setup:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	cargo clean

$(ASM_SRC)/bios.asm:
	echo "> ERROR: Could not find source file bios.asm"
	@exit 1

$(IMG_FILE): $(BUILD_DIR)/brmain.bin
	@echo "> Creating zeroed image..."
	@dd if=/dev/zero of=$(IMG_FILE) bs=512 count=2880
	@echo "> Copying boot record..."
	@dd if=$(BUILD_DIR)/brmain.bin of=$(IMG_FILE) conv=notrunc
	@echo "> Boot image built."

$(BUILD_DIR)/brmain.bin: $(ASM_SRC)/brmain.asm
	$(NASM) $(ASM_SRC)/brmain.asm -f bin -o $@

.PHONY: qemu setup all clean build
