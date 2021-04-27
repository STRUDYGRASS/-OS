/*
 * @Description: process wrote by C
 * @Version: 
 * @Autor: Yunfei
 * @Date: 2021-03-21 16:56:36
 * @LastEditors: Yunfei
 * @LastEditTime: 2021-04-18 16:46:14
 */

#include "head_unit.h"

// #include "string.h"

PUBLIC int kernel_main(){
    // disp_str("-----\"kernel_main\" begins-----\n");

	TASK*		p_task		= task_table;
	PROCESS*	p_proc		= proc_table;
	char*		p_task_stack	= task_stack + STACK_SIZE_TOTAL;
	u16		selector_ldt	= SELECTOR_LDT_FIRST;
	int prio;
	int i,j;

	u8              privilege;
	u8              rpl;
	int             eflags;

	for (i = 0; i < NR_TASKS + NR_PROCS; i++) {
		if (i >= NR_TASKS + NR_NATIVE_PROCS){
			p_proc->p_flags = FREE_SLOT;
			continue;
		}
		if (i < NR_TASKS) {     /* 任务 */
                        p_task    = task_table + i;
                        privilege = PRIVILEGE_TASK;
                        rpl       = RPL_TASK;
                        eflags    = 0x1202; /* IF=1, IOPL=1, bit 2 is always 1 */
						prio      = 15;
                }
		else {                  /* 用户进程 */
                        p_task    = user_proc_table + (i - NR_TASKS);
                        privilege = PRIVILEGE_USER;
                        rpl       = RPL_USER;
                        eflags    = 0x202; /* IF=1, bit 2 is always 1 */
						prio      = 5;
                }
		strcpy(p_proc->p_name, p_task->name);	// name of the process
		// p_proc->pid = i;			// pid
		p_proc->p_parent = NO_TASK;

		// p_proc->ldt_sel = selector_ldt; 移到protect中声明

		// memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3],
		//        sizeof(DESCRIPTOR));
		// p_proc->ldts[0].attr1 = DA_C | privilege << 5;;
		// memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3],
		//        sizeof(DESCRIPTOR));
		// p_proc->ldts[1].attr1 = DA_DRW | privilege << 5;

		if (strcmp(p_task->name, "INIT") != 0) {
			p_proc->ldts[INDEX_LDT_C]  = gdt[SELECTOR_KERNEL_CS >> 3];
			p_proc->ldts[INDEX_LDT_RW] = gdt[SELECTOR_KERNEL_DS >> 3];

			/* change the DPLs */
			p_proc->ldts[INDEX_LDT_C].attr1  = DA_C   | privilege << 5;
			p_proc->ldts[INDEX_LDT_RW].attr1 = DA_DRW | privilege << 5;
		}
		else {		/* INIT process */
			unsigned int k_base;
			unsigned int k_limit;
			int ret = get_kernel_map(&k_base, &k_limit);
			assert(ret == 0);
			init_descriptor(&p_proc->ldts[INDEX_LDT_C],
				  0, /* bytes before the entry point
				      * are useless (wasted) for the
				      * INIT process, doesn'p_task matter
				      */
				  (k_base + k_limit) >> LIMIT_4K_SHIFT,
				  DA_32 | DA_LIMIT_4K | DA_C | privilege << 5);

			init_descriptor(&p_proc->ldts[INDEX_LDT_RW],
				  0, /* bytes before the entry point
				      * are useless (wasted) for the
				      * INIT process, doesn'p_task matter
				      */
				  (k_base + k_limit) >> LIMIT_4K_SHIFT,
				  DA_32 | DA_LIMIT_4K | DA_DRW | privilege << 5);
		}

		//与之前意义相同，只是这里多写了一步
		p_proc->regs.cs = INDEX_LDT_C << 3 | SA_TIL | rpl;
		p_proc->regs.ds = INDEX_LDT_RW << 3 | SA_TIL | rpl;
		p_proc->regs.es = INDEX_LDT_RW << 3 | SA_TIL | rpl;
		p_proc->regs.fs = INDEX_LDT_RW << 3 | SA_TIL | rpl;
		p_proc->regs.ss = INDEX_LDT_RW << 3 | SA_TIL | rpl;

		p_proc->regs.gs	= (SELECTOR_KERNEL_GS & SA_RPL_MASK) | rpl;

		p_proc->regs.eip = (u32)p_task->initial_eip;
		p_proc->regs.esp = (u32)p_task_stack; //栈顶指针
		p_proc->regs.eflags = eflags;

		p_proc->p_flags = 0;
		p_proc->p_msg = 0;
		p_proc->p_recvfrom = NO_TASK;
		p_proc->p_sendto = NO_TASK;
		p_proc->has_int_msg = 0;
		p_proc->q_sending = 0;
		p_proc->next_sending = 0;

		p_proc->ticks = p_proc->priority = prio;

		p_task_stack -= p_task->stacksize;
		p_proc++;
		p_task++;
		// selector_ldt += 1 << 3; LDT有变动！！！

		for (j = 0; j < NR_FILES; j++)
			p_proc->filp[j] = 0;

	}

    k_reenter = 0;
	ticks = 0;

	p_proc_ready	= proc_table; 

	// proc_table[NR_TASKS + 0].nr_tty = 0;
	// proc_table[NR_TASKS + 1].nr_tty = 1;
	// proc_table[NR_TASKS + 2].nr_tty = 1;

	init_clock();
	// init_keyboard(); 放入tty中初始化

	restart();

	while(1){}
}

/*****************************************************************************
 *                                get_ticks
 *****************************************************************************/
PUBLIC int get_ticks()
{
	MESSAGE msg;
	reset_msg(&msg);
	msg.type = GET_TICKS;
	send_recv(BOTH, TASK_SYS, &msg);
	return msg.RETVAL;
}


void TestA()
{
	for(;;);
	int fd;
	int i, n;

	char filename[MAX_FILENAME_LEN+1] = "blah";
	const char bufw[] = "abcde";
	const int rd_bytes = 3;
	char bufr[rd_bytes];

	assert(rd_bytes <= strlen(bufw));

	/* create */
	fd = open(filename, O_CREAT | O_RDWR);
	assert(fd != -1);
	printl("File created: %s (fd %d)\n", filename, fd);

	/* write */
	n = write(fd, bufw, strlen(bufw));
	assert(n == strlen(bufw));

	/* close */
	close(fd);

	/* open */
	fd = open(filename, O_RDWR);
	assert(fd != -1);
	printl("File opened. fd: %d\n", fd);

	/* read */
	n = read(fd, bufr, rd_bytes);
	assert(n == rd_bytes);
	bufr[n] = 0;
	printl("%d bytes read: %s\n", n, bufr);

	/* close */
	close(fd);

	spin("testa");
}

void TestB()
{
	char tty_name[] = "/dev_tty1";

	int fd_stdin  = open(tty_name, O_RDWR);
	assert(fd_stdin  == 0);
	int fd_stdout = open(tty_name, O_RDWR);
	assert(fd_stdout == 1);

	char rdbuf[128];

	while (1) {
		printf("$ ");
		int r = read(fd_stdin, rdbuf, 70);
		rdbuf[r] = 0;

		if (strcmp(rdbuf, "hello") == 0)
			printf("hello world!\n");
		else
			if (rdbuf[0])
				printf("{%s}\n", rdbuf);
	}

	assert(0); /* never arrive here */
}

void TestC()
{
	while(1){
		// disp_str("C");
		// disp_str(".");
		delay(1);
	}
}

/*****************************************************************************
 *                                Init
 *****************************************************************************/
/**
 * The hen.
 * 
 *****************************************************************************/
void Init()
{
	int fd_stdin  = open("/dev_tty0", O_RDWR);
	assert(fd_stdin  == 0);
	int fd_stdout = open("/dev_tty0", O_RDWR);
	assert(fd_stdout == 1);

	printf("Init() is running ...\n");

	/* extract `cmd.tar' */
	// untar("/cmd.tar");
			

	int pid = fork();
	if (pid != 0) { /* parent process */
		printf("parent is running, child pid:%d\n", pid);
		spin("parent");
	}
	else {	/* child process */
		printf("child is running, pid:%d\n", getpid());
		spin("child");
	}

	assert(0);
}


/*****************************************************************************
 *                                panic
 *****************************************************************************/
PUBLIC void panic(const char *fmt, ...)
{
	int i;
	char buf[256];

	/* 4 is the size of fmt in the stack */
	va_list arg = (va_list)((char*)&fmt + 4);

	i = vsprintf(buf, fmt, arg);

	printl("%c !!panic!! %s", MAG_CH_PANIC, buf);

	/* should never arrive here */
	__asm__ __volatile__("ud2");
}