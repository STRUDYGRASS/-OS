/*
 * @Description: stirng function allert
 * @Version: 
 * @Autor: Yunfei
 * @Date: 2021-04-25 16:54:07
 * @LastEditors: Yunfei
 * @LastEditTime: 2021-04-25 16:55:35
 */

#ifndef	_YUNFEI_STRING_H
#define	_YUNFEI_STRING_H
/* string.asm */
PUBLIC char*	strcpy(char* dst, const char* src);
PUBLIC void*    memcpy(void* p_dst, void* p_src, int size);
PUBLIC void     memset(void* p_dst, char ch, int size);
PUBLIC int      strlen(const char* s);

/**
 * `phys_copy' and `phys_set' are used only in the kernel, where segments
 * are all flat (based on 0). In the meanwhile, currently linear address
 * space is mapped to the identical physical address space. Therefore,
 * a `physical copy' will be as same as a common copy, so does `phys_set'.
 */
#define	phys_copy	memcpy
#define	phys_set	memset

#endif