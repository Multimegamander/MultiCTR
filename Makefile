rwildcard   = $(foreach d, $(wildcard $1*), $(filter $(subst *, %, $2), $d) $(call rwildcard, $d/, $2))

NAME       := MultiCTR
REVISION 	 := 1.0.0
SUBFOLDERS := arm9 arm11 sysmodules patches k11_extension

CC 				 := arm-none-eabi-gcc
AS 			   := arm-none-eabi-as
LD 				 := arm-none-eabi-ld
OC 				 := arm-none-eabi-objcopy

PYTHON 		 := python3

.PHONY:	      all release clean $(SUBFOLDERS)
all:		      MultiCTR.firm
release:		  $(NAME)$(REVISION).zip
clean:				@$(foreach dir, $(SUBFOLDERS), $(MAKE) -C $(dir) clean &&) true
							@rm -rf *.firm *.zip

$(NAME)$(REVISION).zip:	boot.firm exception_dump_parser
												@zip -r $@ $^ -x "*.DS_Store*" "*__MACOSX*"
MultiCTR.firm:					$(SUBFOLDERS)
												@firmtool build $@ -D arm11/arm11.elf arm9/arm9.elf k11_extension/k11_extension.elf \
												-A 0x18180000 -C XDMA XDMA NDMA XDMA
												@echo built... $(notdir $@)
$(subfolders):
												@$(MAKE) -C $@ all
