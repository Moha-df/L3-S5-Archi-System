#include <errno.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

#define CHK(op)                                                                \
    do                                                                         \
    {                                                                          \
        if ((op) == -1)                                                        \
            raler(#op);                                                        \
    } while (0)
#define CHKN(op)                                                               \
    do                                                                         \
    {                                                                          \
        if ((op) == NULL)                                                      \
            raler(#op);                                                        \
    } while (0)
#define TCHK(op)                                                               \
    do                                                                         \
    {                                                                          \
        if ((errno = (op)) > 0)                                                \
            raler(#op);                                                        \
    } while (0)

noreturn void raler(char *msg)
{
    perror(msg);
    exit(1);
}

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s D P C B\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    int d, p, c, b;

    if (argc != 5)
        usage(argv[0]);

    d = atoi(argv[1]);
    p = atoi(argv[2]);
    c = atoi(argv[3]);
    b = atoi(argv[4]);
    if (d <= 0 || p <= 0 || c <= 0 || b <= 0)
        usage(argv[0]);

    exit(0);
}
