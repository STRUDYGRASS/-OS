/*
 * @Description: 包含调试和运行代码的最小库和宏定义
 * @Version: 
 * @Autor: Yunfei
 * @Date: 2021-04-23 19:40:37
 * @LastEditors: Yunfei
 * @LastEditTime: 2021-04-23 19:45:34
 */

/* the assert macro */
#define ASSERT
#ifdef ASSERT
void assertion_failure(char *exp, char *file, char *base_file, int line);
#define assert(exp)  if (exp) ; \
        else assertion_failure(#exp, __FILE__, __BASE_FILE__, __LINE__)
#else
#define assert(exp)
#endif

/* EXTERN */
#define	EXTERN	extern	/* EXTERN is defined as extern except in global.c */

/* 函数类型 */
#define	PUBLIC		/* PUBLIC is the opposite of PRIVATE */
#define	PRIVATE	static	/* PRIVATE x limits the scope of x */

/* STRING  */
#define	STR_DEFAULT_LEN	1024

#define	O_CREAT		1
#define	O_RDWR		2

#define SEEK_SET	1
#define SEEK_CUR	2
#define SEEK_END	3

#define	MAX_PATH	128


/*--------*/
/* 库函数 */
/*--------*/
/* lib/open.c */
PUBLIC	int	open		(const char *pathname, int flags);

/* lib/close.c */
PUBLIC	int	close		(int fd);

/* lib/read.c */
PUBLIC int	read		(int fd, void *buf, int count);

/* lib/write.c */
PUBLIC int	write		(int fd, const void *buf, int count);

/* lib/unlink.c */
PUBLIC	int	unlink		(const char *pathname);

/* lib/getpid.c */
PUBLIC int	getpid		();

/* lib/syslog.c */
PUBLIC	int	syslog		(const char *fmt, ...);