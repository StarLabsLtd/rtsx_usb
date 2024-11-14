# rtsx_usb

obj-m := rtsx_usb.o

KERNEL_BUILD := /lib/modules/$(shell uname -r)/build

EXTRA_CFLAGS += -DDEBUG

MODULE_PATH := /lib/modules/$(shell uname -r)/kernel/drivers/misc/cardreader
KO_FILE := rtsx_usb.ko
KO_BAK_FILE := $(KO_FILE).bak
KO_ZST_FILE := $(KO_FILE).zst

all:	install

rtsx_usb.ko:
	make -C $(KERNEL_BUILD) M=$(PWD) modules

install:rtsx_usb.ko
	# If .ko already exists, move it to .ko.bak (only if .ko.bak doesn't already exist)
	if [ -f $(MODULE_PATH)/$(KO_FILE) ]; then \
		if [ ! -f $(MODULE_PATH)/$(KO_BAK_FILE) ]; then \
			sudo mv $(MODULE_PATH)/$(KO_FILE) $(MODULE_PATH)/$(KO_BAK_FILE); \
		else \
			echo "$(KO_BAK_FILE) already exists, not overriding."; \
		fi \
	fi
	# Install .ko file, using zstd compression if available, or fallback to copying the .ko
	if command -v zstd > /dev/null 2>&1; then \
		sudo zstd -f --compress $(KO_FILE) -o $(MODULE_PATH)/$(KO_ZST_FILE); \
	else \
		sudo cp $(KO_FILE) $(MODULE_PATH)/$(KO_FILE); \
	fi
	sudo depmod -a
	sudo modprobe -r rtsx_usb_ms rtsx_usb_sdmmc rtsx_usb
	sudo modprobe rtsx_usb
	sudo modprobe rtsx_usb_ms
	sudo modprobe rtsx_usb_sdmmc

uninstall:
	# If .ko.bak exists, rename it to .ko
	if [ -f $(MODULE_PATH)/$(KO_BAK_FILE) ]; then \
		sudo mv $(MODULE_PATH)/$(KO_BAK_FILE) $(MODULE_PATH)/$(KO_FILE); \
	fi
	# If .ko exists, remove it (but don't override .bak if present)
	if [ -f $(MODULE_PATH)/$(KO_FILE) ]; then \
		sudo rm $(MODULE_PATH)/$(KO_FILE); \
	fi
	sudo depmod -a
	sudo modprobe -r rtsx_usb_ms rtsx_usb_sdmmc rtsx_usb
	sudo modprobe rtsx_usb
	sudo modprobe rtsx_usb_ms
	sudo modprobe rtsx_usb_sdmmc

clean:
	make -C $(KERNEL_BUILD) M=$(PWD) clean

.PHONY: install clean uninstall
