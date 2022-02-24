#include "stdio.h"

int main(int argc, char * argv[])
{
	int argcc = argc;
	char** argvv = argv;
	int i;
	for (i = 1; i < argcc; i++)
		printf("%s%s", i == 1 ? "" : " ", argvv[i]);
	printf("\n");

	return 0;
}
