/*****************************************************************************
 * @Description: 
 * @Version: 
 * @Autor: Yunfei
 * @Date: 2021-04-19 19:53:07
 * @LastEditors: Yunfei
 * @LastEditTime: 2021-04-21 15:28:07
******************************************************************************/
#include "head_unit.h"

#include "hd.h"



/*****************************************************************************
 *                                task_fs
 *****************************************************************************/
/**
 * <Ring 1> The main loop of TASK FS.
 * 
 *****************************************************************************/
PUBLIC void task_fs()
{
	printl("Task FS begins.\n");

	/* open the device: hard disk */
	MESSAGE driver_msg;
	driver_msg.type = DEV_OPEN;
	send_recv(BOTH, TASK_HD, &driver_msg);

	spin("FS");
	while(1){}
}