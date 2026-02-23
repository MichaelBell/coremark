PROJECT_NAME ?= coremark

PORT_SRCS = rv4028/core_portme.c

CORE_FILES = core_list_join core_main core_matrix core_state core_util
ORIG_SRCS = $(addsuffix .c,$(CORE_FILES))
PROJECT_SOURCES = $(ORIG_SRCS) $(PORT_SRCS)

RISCV_TOOLCHAIN ?= /opt/rv4028

CC = $(RISCV_TOOLCHAIN)/bin/riscv32-unknown-elf-gcc
AS = $(RISCV_TOOLCHAIN)/bin/riscv32-unknown-elf-as
AR = $(RISCV_TOOLCHAIN)/bin/riscv32-unknown-elf-ar
LD = $(RISCV_TOOLCHAIN)/bin/riscv32-unknown-elf-ld
OBJCOPY = $(RISCV_TOOLCHAIN)/bin/riscv32-unknown-elf-objcopy

RV4028_SDK ?= $(HOME)/riscv/rv4028-sdk

all: $(PROJECT_NAME).uf2

clean:
	cd $(dir $(PROJECT_NAME)) && rm *.o *.elf *.bin *.uf2 rv4028/*.o

%.o: %.c
	$(CC) -DITERATIONS=0 -DPERFORMANCE_RUN -O2 -march=rv32i -I$(RV4028_SDK) -Irv4028/ -I. -nostdlib -nostartfiles -ffreestanding -ffunction-sections -fdata-sections -Wall -Werror -Wno-format -lc -c $< -o $@

%.o: %.s
	$(AS) -march=rv32i_zicsr $< -o $@

$(PROJECT_NAME).elf: $(PROJECT_SOURCES:.c=.o) 
	$(LD) $^ $(RV4028_SDK)/start.o $(RV4028_SDK)/rv4028.a $(RISCV_TOOLCHAIN)/riscv32-unknown-elf/lib/libc.a $(RISCV_TOOLCHAIN)/riscv32-unknown-elf/lib/libm.a $(RISCV_TOOLCHAIN)/lib/gcc/riscv32-unknown-elf/*/libgcc.a -T $(RV4028_SDK)/memmap --gc-sections -o $@

$(PROJECT_NAME).bin: $(PROJECT_NAME).elf
	$(OBJCOPY) $< -O binary $@

$(PROJECT_NAME).uf2: $(PROJECT_NAME).bin
	$(RV4028_SDK)/mkuf2.py $< $@

prog: $(PROJECT_NAME).uf2
	picotool load -f $(PROJECT_NAME).uf2

.PHONY: all prog clean
