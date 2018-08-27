#!/usr/bin/make -f 
# -----------------------------------------------
# install.mk - (c) 2018 James Renwick
#
# Downloads and cross-compiles GCC and binutils
# Installs into /usr/os-workshop-gcc

# The install directory (do not change!)
export PREFIX ?= /usr/os-workshop-gcc
# The target architecture
export TARGET ?= i686-elf
# The version of GCC to build
export TARGET_GCC ?= gcc-8.2.0
# The version of binutils to build
export TARGET_BINUTILS ?= binutils-2.31
# The directory in which to build
export BUILD_DIR ?= build

export PATH := $(PREFIX)/bin:$(PATH)
SRC_APT := g++ python xz-utils bison flex libgmp3-dev libmpfr-dev libmpc-dev texinfo

.PHONY: bootstrap build-all gcc binutils clean-all clean-binutils clean-gcc uninstall

bootstrap: $(PREFIX)
	sudo apt install $(SRC_APT)
	mkdir -p $(BUILD_DIR)
	$(MAKE) -C $(BUILD_DIR) -j 2 -f $(abspath $(CURDIR)/install.mk) build-all

$(PREFIX):
	sudo mkdir -p $(PREFIX)
	sudo chmod -R a+rwx $(PREFIX)

$(TARGET_GCC).tar.xz:
	wget https://ftp.gnu.org/gnu/gcc/$(TARGET_GCC)/$(TARGET_GCC).tar.xz

$(TARGET_BINUTILS).tar.xz:
	wget https://ftp.gnu.org/gnu/binutils/$(TARGET_BINUTILS).tar.xz

$(TARGET_GCC): $(TARGET_GCC).tar.xz
	tar -xJf $(TARGET_GCC).tar.xz

$(TARGET_BINUTILS): $(TARGET_BINUTILS).tar.xz
	tar -xJf $(TARGET_BINUTILS).tar.xz

build-binutils/Makefile: $(TARGET_BINUTILS)
	mkdir -p build-binutils
	cd build-binutils && ../$(TARGET_BINUTILS)/configure --target=$(TARGET) --prefix="$(PREFIX)" --with-sysroot --disable-nls --disable-werror

$(PREFIX)/bin/$(TARGET)-as: build-binutils/Makefile
	cd build-binutils && $(MAKE) -j 8
	cd build-binutils && $(MAKE) -j 8 install

build-gcc/Makefile: $(PREFIX)/bin/$(TARGET)-as $(TARGET_GCC)
	# First patch configuration when building for x64
ifeq ($(TARGET),x86_64-elf)
	python $(dir $(abspath $(MAKEFILE_LIST)))/patch64.py $(TARGET_GCC)/gcc/config.gcc
	printf "MULTILIB_OPTIONS += mno-red-zone\nMULTILIB_DIRNAMES += no-red-zone" > $(TARGET_GCC)/gcc/config/i386/t-x86_64-elf
endif
	mkdir build-gcc
	cd build-gcc && ../$(TARGET_GCC)/configure --target=$(TARGET) --prefix="$(PREFIX)" --disable-nls --enable-languages=c,c++ --without-headers

$(PREFIX)/bin/$(TARGET)-gcc: build-gcc/Makefile
	which -- $(TARGET)-as || { echo "Target binutils not in path" && exit 1; }
	cd build-gcc && $(MAKE) -j 8 all-gcc
	cd build-gcc && $(MAKE) -j 8 all-target-libgcc
	cd build-gcc && $(MAKE) -j 8 install-gcc
	cd build-gcc && $(MAKE) -j 8 install-target-libgcc

binutils: $(PREFIX) $(PREFIX)/bin/$(TARGET)-as

gcc: $(PREFIX) $(PREFIX)/bin/$(TARGET)-gcc

clean-binutils:
	rm -rf $(BUILD_DIR)/build-binutils
clean-gcc:
	rm -rf $(BUILD_DIR)/build-gcc
clean-all:
	rm -rf $(BUILD_DIR)

build-all: gcc
	$(TARGET)-gcc --version

	@echo ==== Build Complete ====
	whereis $(TARGET)-gcc

	rm -rf build-binutils build-gcc $(TARGET_BINUTILS) $(TARGET_GCC)

uninstall: clean-all
	rm -rf $(PREFIX)
