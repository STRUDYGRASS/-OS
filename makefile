# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT	= 0x30400

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET	=   0x400


# Programs, flags, etc.
ASM		= nasm
DASM		= ndisasm
CC		= gcc
LD		= ld
ASMBFLAGS	= -I boot/include/
ASMKFLAGS	= -I include/ -f elf
CFLAGS		= -I include/ -c -fno-builtin -m32  -fno-stack-protector
LDFLAGS		= -s -Ttext $(ENTRYPOINT) -m elf_i386
DASMFLAGS	= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# This Program
OSBOOT = boot/boot.bin boot/loader.bin
OSKERNEL = kernel.bin
OBJS = kernel/kernel.o kernel/start.o kernel/main.o \
		kernel/clock.o kernel/syscall.o \
		kernel/keyboard.o kernel/tty.o kernel/console.o \
		kernel/i8259.o kernel/global.o kernel/protect.o \
		lib/kliba.o  lib/string.o lib/klib.o
DASMOUTPUT = kernel.bin.asm

# 关于C的借助gcc和.d文件的自动寻找依赖可以实现，然而最后还是希望能够手打依赖——因为目前所涉及的项目还是不算巨大，可以加深映像;具体的实现在隔壁

# ALL Phony Targets
.PHONY: everything final image clean realclean disasm all buildimg

# default starting position
nop :
	@echo "why not \`make image' huh? :)"
everything: $(OSBOOT) $(OSKERNEL)

all: realclean everything

final: all clean

image: final buildimg

clean: 
	rm -f $(OBJS)

realclean:
	rm -f $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

disasm :
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)

buildimg :
	dd if=boot/boot.bin of=a.img bs=512 count=1 conv=notrunc
	sudo mount -o loop a.img /mnt/floppy/
	sudo cp -fv boot/loader.bin /mnt/floppy/
	sudo cp -fv kernel.bin /mnt/floppy
	sudo umount /mnt/floppy

boot/boot.bin : boot/boot.asm boot/include/load.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

boot/loader.bin : boot/loader.asm boot/include/load.inc \
			boot/include/fat12hdr.inc boot/include/pm.inc
	$(ASM) $(ASMBFLAGS) -o $@ $<

$(OSKERNEL) : $(OBJS)
	$(LD) $(LDFLAGS) -o $(OSKERNEL) $(OBJS)

# kernel element
kernel/kernel.o : kernel/kernel.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/start.o : kernel/start.c include/const.h include/protect.h include/type.h include/global.h include/string.h\
				include/proto.h include/proc.h
	$(CC)  $(CFLAGS) -o $@ $<

kernel/main.o: kernel/main.c include/type.h include/const.h include/protect.h include/string.h include/proc.h include/proto.h \
			include/global.h
	$(CC) $(CFLAGS) -o $@ $<


kernel/i8259.o: kernel/i8259.c include/type.h include/const.h include/protect.h \
 			include/proto.h
	$(CC)  $(CFLAGS) -o $@ $<

kernel/global.o: kernel/global.c include/type.h include/const.h include/protect.h include/proc.h \
			include/global.h include/proto.h
	$(CC)  $(CFLAGS) -o $@ $<

kernel/protect.o : kernel/protect.c include/type.h include/const.h include/protect.h include/proc.h include/proto.h \
			include/global.h
	$(CC)  $(CFLAGS) -o $@ $<

kernel/clock.o : kernel/clock.c
	$(CC)  $(CFLAGS) -o $@ $<

kernel/syscall.o : kernel/syscall.asm include/sconst.inc
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/keyboard.o : kernel/keyboard.c include/keymap.h
	$(CC)  $(CFLAGS) -o $@ $<

kernel/tty.o : kernel/tty.c
	$(CC)  $(CFLAGS) -o $@ $<

kernel/console.o : kernel/console.c
	$(CC)  $(CFLAGS) -o $@ $<

# Library
lib/klib.o : lib/klib.c include/type.h include/const.h include/protect.h \
		 include/proto.h include/string.h include/global.h
	$(CC)  $(CFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<