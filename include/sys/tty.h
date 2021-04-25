
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				tty.h
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifndef _ORANGES_TTY_H_
#define _ORANGES_TTY_H_


#define TTY_IN_BYTES	256	/* tty input queue size */
#define TTY_OUT_BUF_LEN		2	/* tty output buffer size */

struct s_console;

/* TTY */
typedef struct s_tty
{
	u32	in_buf[TTY_IN_BYTES];	/* TTY 输入缓冲区 */
	u32*	p_inbuf_head;		/* 指向缓冲区中下一个空闲位置 */
	u32*	p_inbuf_tail;		/* 指向键盘任务应处理的键值 */
	int	inbuf_count;		/* 缓冲区中已经填充了多少 */

	int	tty_caller;			/* 发送消息的进程pid */
	int	tty_procnr;			/* 请求消息的进程pid */
	void*	tty_req_buf;	/* 请求消息的进程缓冲区地址 */
	int	tty_left_cnt;		/* 请求消息的进程读入字符数 */
	int	tty_trans_cnt;		/* 请求消息的进程已读入字符数 */

	struct s_console *	p_console;
}TTY;


#endif /* _ORANGES_TTY_H_ */
