
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            proto.h

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
#ifndef	_YUNFEI_PROTO_H
#define	_YUNFEI_PROTO_H

/* klib.asm */
PUBLIC void	out_byte(u16 port, u8 value);
PUBLIC u8	in_byte(u16 port);
PUBLIC void	disp_str(char * info);
PUBLIC void	disp_color_str(char * info, int color);
PUBLIC void	disable_irq(int irq);
PUBLIC void	enable_irq(int irq);
PUBLIC void	port_read(u16 port, void* buf, int n);
PUBLIC void	port_write(u16 port, void* buf, int n);
PUBLIC void	disable_int();
PUBLIC void	enable_int();

/* string.asm */
PUBLIC char*	strcpy(char* dst, const char* src);
PUBLIC void*    memcpy(void* p_dst, void* p_src, int size);
PUBLIC void     memset(void* p_dst, char ch, int size);
PUBLIC unsigned int strlen(const char* s);
/**
 * `phys_copy' and `phys_set' are used only in the kernel, where segments
 * are all flat (based on 0). In the meanwhile, currently linear address
 * space is mapped to the identical physical address space. Therefore,
 * a `physical copy' will be as same as a common copy, so does `phys_set'.
 */
#define	phys_copy	memcpy
#define	phys_set	memset

/* protect.c */
PUBLIC void	init_prot();
PUBLIC u32	seg2phys(u16 seg);

/* klib.c */
PUBLIC void	delay(int time);
PUBLIC void	disp_int(int input);
PUBLIC char *	itoa(char * str, int num);

/* kernel.asm */
void restart();

/* systask.c */
PUBLIC void task_sys();

/* main.c */
PUBLIC int  get_ticks();
void TestA();
void TestB();
void TestC();
PUBLIC void panic(const char *fmt, ...);

/* i8259.c */
PUBLIC void put_irq_handler(int irq, irq_handler handler);
PUBLIC void init_8259A();
PUBLIC void spurious_irq(int irq);

/* clock.c */
PUBLIC void clock_handler(int irq);
PUBLIC void init_clock();

/* fs/main.c */
PUBLIC void task_fs();

/* kernel/hd.c */
PUBLIC void	task_hd();
PUBLIC void	hd_handler(int irq);

/* keyboard.c */
PUBLIC void init_keyboard();
PUBLIC void keyboard_read(TTY* p_tty);

/* tty.c */
PUBLIC void task_tty();
PUBLIC void in_process(TTY* p_tty, u32 key);

/* console.c */
PUBLIC void out_char(CONSOLE* p_con, char ch);
PUBLIC void scroll_screen(CONSOLE* p_con, int direction);
PUBLIC void select_console(int nr_console);
PUBLIC void init_screen(TTY* p_tty);
PUBLIC int  is_current_console(CONSOLE* p_con);;

/* printf.c */
PUBLIC  int     printf(const char *fmt, ...);
#define	printl	printf

/* vsprintf.c */
PUBLIC  int     vsprintf(char *buf, const char *fmt, va_list args);
PUBLIC	int	sprintf(char *buf, const char *fmt, ...);

/* proc.c */
PUBLIC	void	schedule();
PUBLIC	void*	va2la(int pid, void* va);
PUBLIC	int	ldt_seg_linear(PROCESS* p, int idx);
PUBLIC	void	reset_msg(MESSAGE* p);
PUBLIC	void	dump_msg(const char * title, MESSAGE* m);
PUBLIC	void	dump_proc(PROCESS * p);
PUBLIC	int	send_recv(int function, int src_dest, MESSAGE* msg);
PUBLIC void	inform_int(int task_nr);

/* lib/misc.c */
PUBLIC void spin(char * func_name);


// /* 以下是系统调用相关 */

/* 系统调用 - 系统级 */
PUBLIC	int	sys_sendrec(int function, int src_dest, MESSAGE* m, PROCESS* p);
PUBLIC	int	sys_printx(int _unused1, int _unused2, char* s, PROCESS * p_proc);

/* syscall.asm */
PUBLIC  void    sys_call();             /* int_handler */


/* 系统调用 - 用户级 */
PUBLIC	int	sendrec(int function, int src_dest, MESSAGE* p_msg);
PUBLIC	int	printx(char* str);

#endif /*YUNFEI_PROTO_H*/