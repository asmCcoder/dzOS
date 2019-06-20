# ToDo - Detect OS Linux or Win
ASM = ./TASM.EXE
ASMFLAGS = -80 -b -a -fFF		# For generating .bin files
#ASMFLAGS = -80 -o10 -g0 -c -a -y	# For generating Intel HEX files
TARGET = dzOS
BINARIES = bin/BIOS.bin bin/BIOS.jblks.bin bin/kernel.bin bin/kernel.jblks.bin bin/CLI.bin
MERGE = bin/BIOS.bin bin/BIOS.jblks.bin bin/kernel.bin bin/kernel.jblks.bin bin/CLI.bin
MKDIR = mkdir -p
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
MAGENTA = \033[0;35m
CYAN = \033[0;36m
WHITE = \033[0;37m

BIOS_MAXSIZE = 832
KERNEL_MAXSIZE = 2064
CLI_MAXSIZE = 2305
VERSION_ADDR = 2624

YEAR = $(shell date +"%Y")
MONTH = $(shell date +"%m")
DAY = $(shell date +"%d")
BUILDDATE_PREV = $(shell cat builddate)
BUILDDATE_NOW = $(YEAR)$(MONTH)$(DAY)
BUILDNUM = $(shell cat buildnum)

ifneq ($(BUILDDATE_NOW), $(BUILDDATE_PREV))
	BUILDNUM := 1
endif

.PHONY: directories 

all: clean $(TARGET)
# Check file size don't exceed configuration
	$(eval bios_fs = $(shell stat --printf="%s" bin/BIOS.bin))
	@if [ $(bios_fs) -gt $(BIOS_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> BIOS.bin is too big! <---$(WHITE)"; fi
	$(eval kernel_fs = $(shell stat --printf="%s" bin/kernel.bin))
	@if [ $(kernel_fs) -gt $(KERNEL_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> kernel.bin is too big! <---$(WHITE)"; fi
	$(eval cli_fs = $(shell stat --printf="%s" bin/CLI.bin))
	@if [ $(cli_fs) -gt $(CLI_MAXSIZE) ]; then echo "$(RED)E R R O R$(MAGENTA): ---> CLI.bin is too big! <---$(WHITE)"; fi

	@echo "$(YELLOW)#### Merging Binaries ####$(WHITE)"
	@cat $(MERGE) > bin/dzOS.$(YEAR).$(MONTH).$(DAY).$(BUILDNUM).bin
# the value for seek MUST be the same as KRN_DZOS_VERSION + 1 in equates.inc, and converted into DEC
	@printf '$(YEAR).$(MONTH).$(DAY).$(BUILDNUM)' | dd of=bin/dzOS.$(YEAR).$(MONTH).$(DAY).$(BUILDNUM).bin bs=1 seek=$(VERSION_ADDR) conv=notrunc status=none
	@echo "$(MAGENTA)#### dzOS binary (version $(YEAR).$(MONTH).$(DAY).$(BUILDNUM)) succesfully created in bin/ ####$(WHITE)"
	$(eval BUILDNUM = $(shell echo $$(($(BUILDNUM) + 1))))
	@echo "$(BUILDNUM)" > buildnum
	@echo "$(BUILDDATE_NOW)" > builddate;

directories:
	@$(MKDIR) bin
	@$(MKDIR) exp
	@$(MKDIR) lst

bin/sysvars.bin: src/sysvars.asm
	@echo "$(GREEN)#### Compiling $(CYAN)sysvars $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/sysvars.asm bin/sysvars.bin lst/sysvars.lst > /tmp/dastaZ80_compile.txt
	@mv src/sysvars.exp exp/
	@rm -f bin/sysvars.bin
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/BIOS.bin: src/BIOS/BIOS.asm
	@echo "$(GREEN)#### Compiling $(CYAN)BIOS $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/BIOS/BIOS.asm bin/BIOS.bin lst/BIOS.lst > /tmp/dastaZ80_compile.txt
	@mv src/BIOS/BIOS.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/BIOS.jblks.bin: src/BIOS/BIOS.jblks.asm
	@echo "$(GREEN)#### Compiling $(CYAN)BIOS Jumpblocks $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/BIOS/BIOS.jblks.asm bin/BIOS.jblks.bin lst/BIOS.jblks.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/kernel.bin: src/kernel/kernel.asm
	@echo "$(GREEN)#### Compiling $(CYAN)Kernel $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/kernel/kernel.asm bin/kernel.bin lst/kernel.lst > /tmp/dastaZ80_compile.txt
	@mv src/kernel/kernel.exp exp/
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/kernel.jblks.bin: src/kernel/kernel.jblks.asm
	@echo "$(GREEN)#### Compiling $(CYAN)Kernel Jumpblocks $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/kernel/kernel.jblks.asm bin/kernel.jblks.bin lst/kernel.jblks.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt

bin/CLI.bin: src/CLI.asm
	@echo "$(GREEN)#### Compiling $(CYAN)CLI $(GREEN)####$(WHITE)"
	@$(ASM) $(ASMFLAGS) src/CLI.asm bin/CLI.bin lst/CLI.lst > /tmp/dastaZ80_compile.txt
	@sed '6!d' /tmp/dastaZ80_compile.txt


$(TARGET): bin/sysvars.bin $(BINARIES)
	

clean:
	@echo "$(YELLOW)#### Cleaning project ####$(WHITE)"
	@rm -f bin/*
	@rm -f exp/*
	@rm -f lst/*

