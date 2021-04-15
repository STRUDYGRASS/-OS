/*
 * @Description: 
 * @Version: 
 * @Autor: Yunfei
 * @Date: 2021-04-15 16:06:48
 * @LastEditors: Yunfei
 * @LastEditTime: 2021-04-15 16:14:53
 */

#include "head_unit.h"

PUBLIC void schedule()
{
    p_proc_ready++;
    if (p_proc_ready >= proc_table + NR_TASKS + NR_PROCS)
		p_proc_ready = proc_table;
}