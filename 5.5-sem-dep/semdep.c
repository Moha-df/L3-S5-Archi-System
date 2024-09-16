#include <assert.h>
#include <errno.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <unistd.h>

// Version spécifique au graphe de l'énoncé

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

#define NTAB(tab) ((int)(sizeof(tab) / sizeof((tab)[0])))

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s\n", argv0);
    exit(1);
}

/*
 * La fonction tâche telle qu'elle est demandée dans l'énoncé avec
 * un petit délai pour voir le parallélisme à l'œuvre
 */

void tache(int num) // num = 11, 12, 13, 21, etc.
{
    printf("T %d\n", num);
    usleep(500 * 1000); // 500 ms pour voir le parallélisme à l'œuvre
}

int main(int argc, char *argv[])
{
    if (argc != 1)
        usage(argv[0]);

    exit(0);
}
