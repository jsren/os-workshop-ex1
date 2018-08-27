#!/usr/bin/make -f 
# -----------------------------------------------
# install.mk - (c) 2018 James Renwick
#
# Downloads and cross-compiles GCC and binutils
# Installs into /usr/os-workshop-gcc
#
# CYGWIN-SPECIFIC: removed 'sudo'

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
SRC_APT := g++ bison flex libgmp3-dev libmpfr-dev libmpc-dev texinfo

.PHONY: bootstrap build-all gcc binutils clean-all clean-binutils clean-gcc uninstall

bootstrap: $(PREFIX)
	#sudo apt install $(SRC_APT) # apt not supported by cygwin
	mkdir -p build
	$(MAKE) -C build -j 2 -f $(abspath $(CURDIR)/install.mk) build-all

$(PREFIX):
	mkdir -p $(PREFIX)
	chmod -R a+rwx $(PREFIX)

%:
	$(MAKE) -f $(abspath $(CURDIR)/install.mk) $@
