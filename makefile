# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT	= 0x1000

# Offset of entry point in kernel file
# It depends on ENTRYPOINT
ENTRYOFFSET	=   0x400


# Programs, flags, etc.
ASM		= nasm
DASM		= ndisasm
CC		= gcc
LD		= ld
ASMBFLAGS	= -I boot/include/
ASMKFLAGS	= -I include/ -I include/sys  -f elf
CFLAGS		= -I include/ -I include/sys    -c -fno-builtin -m32  -fno-stack-protector \
# # -fpack-struct  -Wno-implicit-function-declaration
#忽略标准库冲突函数，强制不进行栈检查， \
-fpack-struct将所有结构成员无缝隙地压缩在一起。因为它使代码程序效率大大降低，且结构成员的偏移量与系统库不相符，\
		这么做有时可能导致寻址错误，所以一般不使用这个选项。\
忽略函数定义未找到警告（asm中）
LDFLAGS		= -s -Ttext $(ENTRYPOINT) -m elf_i386
DASMFLAGS	= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)
ARFLAGS		= rcs

# This Program
OSBOOT = boot/boot.bin boot/loader.bin
OSKERNEL = kernel.bin
OBJS = kernel/kernel.o kernel/start.o kernel/main.o \
		kernel/clock.o kernel/syscall.o kernel/proc.o \
		kernel/systask.o kernel/hd.o \
		kernel/keyboard.o kernel/tty.o kernel/console.o \
		kernel/printf.o kernel/vsprintf.o \
		kernel/i8259.o kernel/global.o kernel/protect.o \
		lib/getpid.o \
		fs/main.o fs/open.o fs/read_write.o fs/link.o fs/misc.o \
		lib/open.o lib/close.o lib/read.o lib/write.o lib/unlink.o lib/stat.o \
		mm/main.o mm/forkexit.o mm/exec.o \
		lib/fork.o lib/exit.o lib/wait.o lib/exec.o \
		lib/kliba.o  lib/string.o lib/klib.o lib/misc.o
DASMOUTPUT = kernel.bin.asm

# 关于C的借助gcc和.d文件的自动寻找依赖可以实现，然而最后还是希望能够手打依赖——因为目前所涉及的项目还是不算巨大，可以加深映像;具体的实现在隔壁
# 另外，将global所涉及的头文件单入一头文件，那么make中的对应文件也可以用一个变量来表示，但是这个make也是起到了一个前期架构展示的作用，后面也不需要加这些东西了，就放着不动了吧
# 严格来说，作者并未按照后面的更新会对global。h造成影响这样更新依赖 × 怪不得不在意啊，后面的架构都要重写233
# 可能后面通信过后，我这前面的就得废掉了吧

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
kernel/kernel.o : kernel/kernel.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/start.o : kernel/start.c 
	$(CC)  $(CFLAGS) -o $@ $<

kernel/main.o: kernel/main.c 
			# include/string.h
	$(CC) $(CFLAGS) -o $@ $<


kernel/i8259.o: kernel/i8259.c 
	$(CC)  $(CFLAGS) -o $@ $<

kernel/global.o: kernel/global.c 
	$(CC)  $(CFLAGS) -o $@ $<

kernel/protect.o : kernel/protect.c 
	$(CC)  $(CFLAGS) -o $@ $<

kernel/clock.o : kernel/clock.c
	$(CC)  $(CFLAGS) -o $@ $<

kernel/syscall.o : kernel/syscall.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

kernel/systask.o : kernel/systask.c 
	$(CC)	$(CFLAGS) -o $@ $<

kernel/proc.o : kernel/proc.c 
	$(CC)  $(CFLAGS) -o $@ $<

kernel/keyboard.o : kernel/keyboard.c
	$(CC)  $(CFLAGS) -o $@ $<

kernel/tty.o : kernel/tty.c
	$(CC)  $(CFLAGS) -o $@ $<

kernel/console.o : kernel/console.c
	$(CC)  $(CFLAGS) -o $@ $<

kernel/printf.o: kernel/printf.c
	$(CC) $(CFLAGS) -o $@ $<

kernel/vsprintf.o: kernel/vsprintf.c
	$(CC) $(CFLAGS) -o $@ $<

# fs
kernel/hd.o: kernel/hd.c
	$(CC) $(CFLAGS) -o $@ $<

fs/main.o : fs/main.c 
	$(CC) $(CFLAGS) -o $@ $<

fs/open.o : fs/open.c 
	$(CC) $(CFLAGS) -o $@ $<

fs/read_write.o : fs/read_write.c 
	$(CC) $(CFLAGS) -o $@ $<

fs/misc.o : fs/misc.c 
	$(CC) $(CFLAGS) -o $@ $<

fs/link.o : fs/link.c 
	$(CC) $(CFLAGS) -o $@ $<

# mm
mm/main.o : mm/main.c 
	$(CC) $(CFLAGS) -o $@ $<

mm/forkexit.o: mm/forkexit.c
	$(CC) $(CFLAGS) -o $@ $<

mm/exec.o: mm/exec.c
	$(CC) $(CFLAGS) -o $@ $<

# Library
lib/klib.o : lib/klib.c
	$(CC)  $(CFLAGS) -o $@ $<

lib/string.o : lib/string.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/kliba.o : lib/kliba.asm
	$(ASM) $(ASMKFLAGS) -o $@ $<

lib/misc.o: lib/misc.c
	$(CC) $(CFLAGS) -o $@ $<	

# ## 系统调用
# getticks is in the main.c

lib/getpid.o: lib/getpid.c
	$(CC) $(CFLAGS) -o $@ $<	

# ## 进程到文件系统的调用接口函数 
lib/open.o: lib/open.c
	$(CC) $(CFLAGS) -o $@ $<	

lib/close.o: lib/close.c
	$(CC) $(CFLAGS) -o $@ $<

lib/read.o: lib/read.c
	$(CC) $(CFLAGS) -o $@ $<

lib/write.o: lib/write.c
	$(CC) $(CFLAGS) -o $@ $<

lib/unlink.o: lib/unlink.c
	$(CC) $(CFLAGS) -o $@ $<

lib/stat.o: lib/stat.c
	$(CC) $(CFLAGS) -o $@ $<

# ## 进程到内存系统的调用接口函数
lib/fork.o: lib/fork.c
	$(CC) $(CFLAGS) -o $@ $<

lib/exit.o: lib/exit.c
	$(CC) $(CFLAGS) -o $@ $<

lib/wait.o: lib/wait.c
	$(CC) $(CFLAGS) -o $@ $<

lib/exec.o: lib/exec.c
	$(CC) $(CFLAGS) -o $@ $<