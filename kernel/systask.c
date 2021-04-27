/*****************************************************************************
 * @Description: system call used recieve & send
 * @Version: 
 * @Autor: Yunfei
 * @Date: 2021-04-18 20:20:52
 * @LastEditors: Yunfei
 * @LastEditTime: 2021-04-27 15:52:46
******************************************************************************/

#include "head_unit.h"

/*****************************************************************************
 *  <Ring 1> The main loop of TASK SYS.
******************************************************************************/
PUBLIC void task_sys()
{
	MESSAGE msg;
	while (1) {
		send_recv(RECEIVE, ANY, &msg);
		int src = msg.source;

		switch (msg.type) {
		case GET_TICKS:
			msg.RETVAL = ticks;
			send_recv(SEND, src, &msg);
			break;
		case GET_PID:
			msg.type = SYSCALL_RET;
			msg.PID = src;
			send_recv(SEND, src, &msg);
			break;
		default:
			panic("unknown msg type");
			break;
		}
	}
}