rwildcard = $(foreach d, $(wildcard $1*), $(filter $(subst *, %, $2), $d) $(call rwildcard, $d/, $2))

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

ifneq ($(strip $(shell firmtool -v 2>&1 | grep usage)),)
$(error "Please install firmtool v1.1 or greater")
endif

include $(DEVKITARM)/base_tools

name := MultiCTR
revision := $(shell git describe --tags --match v[0-9]* --abbrev=8 | sed 's/-[0-9]*-g/-/')
version_major := $(shell git describe --tags --match v[0-9]* | cut -c2- | cut -f1 -d- | cut -f1 -d.)
version_minor := $(shell git describe --tags --match v[0-9]* | cut -c2- | cut -f1 -d- | cut -f2 -d.)
version_build := $(shell git describe --tags --match v[0-9]* | cut -c2- | cut -f1 -d- | cut -f3 -d.)
commit := $(shell git rev-parse --short=8 HEAD)
is_release := 0

ifeq ($(strip $(revision)),)
	revision := v0.0.0-0
	version_major := 0
	version_minor := 0
	version_build := 0
endif

ifeq ($(strip $(commit)),)
	commit := 0
endif

ifeq ($(strip $(version_build)),)
	version_build := 0
endif

ifeq ($(strip $(shell git describe --tags --match v[0-9]* | grep -)),)
	is_release := 1
endif

dir_arm9 := arm9
dir_arm11 := arm11
dir_bootloader := bootloader
dir_exceptions := exceptions
dir_arm9_exceptions := $(dir_exceptions)/arm9
dir_k11_extension := k11_extension
dir_sysmodules := sysmodules
dir_loader := $(dir_sysmodules)/loader
dir_ntr := $(dir_sysmodules)/ntr
dir_build := build
dir_out := out

ASFLAGS := -mcpu=arm946e-s
CFLAGS := -Wall -Wextra $(ASFLAGS) -fno-builtin -std=c11 -Wno-main -O2 -flto -ffast-math
LDFLAGS := -nostartfiles -Wl,--nmagic

objects = $(patsubst $(dir_source)/%.s, $(dir_build)/%.o, \
          $(patsubst $(dir_source)/%.c, $(dir_build)/%.o, \
          $(call rwildcard, $(dir_source), *.s *.c)))

bundled = $(dir_build)/boorloader.bin.o $(dir_build)/arm9_exceptions.bin.o

modules = $(dir_build)/loader.cxi $(dir_build)/ntr.cxi

define bin2o
	bin2s $< | $(AS) -o $(@)
endef

.PHONY: all
all: firm

.PHONY: release
release: $(dir_out)/$(name)$(revision).zip

.PHONY: firm
firm: $(dir_out)/MultiCTR.firm

.PHONY: clean
clean:
	@$(MAKE) -C $(dir_arm11) clean
	@$(MAKE) -C $(dir_bootloader) clean
	@$(MAKE) -C $(dir_arm9_exceptions) clean
	@$(MAKE) -C $(dir_k11_extension) clean
	@$(MAKE) -C $(dir_loader) clean
	@$(MAKE) -C $(dir_ntr) clean
	@rm -rf $(dir_out) $(dir_build)

.PRECIOUS: $(dir_build)/%.bin

.PHONY: $(dir_arm11)
.PHONY: $(dir_bootloader)
.PHONY: $(dir_arm9_exceptions)
.PHONY: $(dir_k11_extension)
.PHONY: $(dir_loader)
.PHONY: $(dir_ntr)

$(dir_out)/$(name)$(revision).zip: all
	@mkdir -p "$(@D)"
	@7z a -mx $@ ./$(@D)/* ./$(dir_exceptions)/exception_dump_parser.py

$(dir_out)/MultiCTR.firm: $(dir_build)/arm11.elf $(dir_build)/arm9.elf $(dir_build)/k11_extension.bin
	@mkdir -p "$(@D)"
	@firmtool build $@ -D $^ -A 0x18180000 0x18000000 -C XDMA XDMA NDMA XDMA

$(dir_build)/arm11.elf: $(dir_arm11)
	@mkdir -p "$(@D)"
	@$(MAKE) -C $<

$(dir_build)/arm9.elf: $(bundled) $(objects)
	$(LINK.o) -T linker.ld $(OUTPUT_OPTION) $^

$(dir_build)/k11_extension.bin: $(dir_k11_extension)
	@mkdir -p "$(@D)"
	@$(MAKE) -C $<

$(dir_build)/loader.cxi: $(dir_loader)
	@mkdir -p "$(@D)"
	@$(MAKE) -C $<

$(dir_build)/ntr.cxi: $(dir_rosalina)
	@mkdir -p "$(@D)"
	@$(MAKE) -C $<

$(dir_build)/%.bin.o: $(dir_build)/%.bin
	@$(bin2o)

$(dir_build)/bootloader.bin: $(dir_chainloader)
	@mkdir -p "$(@D)"
	@$(MAKE) -C $<

$(dir_build)/arm9_exceptions.bin: $(dir_arm9_exceptions)
	@mkdir -p "$(@D)"
	@$(MAKE) -C $<

$(dir_build)/%.bin: $(dir_patches)/%.s
	@mkdir -p "$(@D)"
	@armips $<

$(dir_build)/memory.o $(dir_build)/strings.o: CFLAGS += -O3
$(dir_build)/config.o: CFLAGS += -DCONFIG_TITLE="\"$(name) $(revision) configuration\""

$(dir_build)/bundled.h: $(bundled)
	@$(foreach f, $(bundled),\
	echo "extern const u8" `(echo $(basename $(notdir $(f))) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"[];" >> $@;\
	echo "extern const u32" `(echo $(basename $(notdir $(f)))| sed -e 's/^\([0-9]\)/_\1/' | tr . _)`_size";" >> $@;\
	)

$(dir_build)/%.o: $(dir_source)/%.c $(dir_build)/bundled.h
	@mkdir -p "$(@D)"
	$(COMPILE.c) $(OUTPUT_OPTION) $<

$(dir_build)/%.o: $(dir_source)/%.s
	@mkdir -p "$(@D)"
	$(COMPILE.s) $(OUTPUT_OPTION) $<
