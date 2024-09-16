#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <unistd.h>

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

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s durée-1%%-en-ms\n", argv0);
    exit(1);
}

// une tâche très lente (enfin, c'est fonction de l'argument du programme)
void *tache(void *arg)
{
    return NULL;
}

// thread : affiche l'avancement et se termine lorsqu'il atteint 100 %
void *gui(void *arg)
{
    return NULL;
}

int main(int argc, char *argv[])
{
    int duree1pcent;

    if (argc != 2)
        usage(argv[0]);

    duree1pcent = atoi(argv[1]);
    if (duree1pcent <= 0)
        usage(argv[0]);

    printf("termine\n");

    exit(0);
}
