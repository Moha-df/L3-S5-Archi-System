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

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

noreturn void usage(char *argv0)
{
    fprintf(stderr, "usage: %s\n", argv0);
    exit(1);
}

#define TOURS 10 * 1000 * 1000
#define NTHREAD 4

long int compteur; // compteur global

int main(int argc, char *argv[])
{
    pthread_t tid[NTHREAD];

    if (argc != 1)
        usage(argv[0]);

    printf("%ld\n", compteur);
    exit(0);
}
