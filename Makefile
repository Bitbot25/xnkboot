NASM=nasm
QEMU=qemu-system-x86_64

ASM_SRC=asm
BUILD_DIR=build

IMG_FILE=$(BUILD_DIR)/boot.img
BOOTREC_SRC=$(ASM_SRC)/bootrec.asm

all: clean build

qemu: $(IMG_FILE)
	$(QEMU) -drive format=raw,file=$(IMG_FILE)

build: setup $(IMG_FILE)

setup:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
	cargo clean

$(IMG_FILE): $(BUILD_DIR)/boot.bin
	@echo "> Creating zeroed image..."
	@dd if=/dev/zero of=$(IMG_FILE) bs=512 count=2880
	@echo "> Copying boot record..."
	@dd if=$(BUILD_DIR)/boot.bin of=$(IMG_FILE) conv=notrunc
	@echo "> Boot image built."

$(BUILD_DIR)/boot.bin: $(BOOTREC_SRC)
	$(NASM) $(BOOTREC_SRC) -f bin -o $@

.PHONY: qemu setup all clean build
