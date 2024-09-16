#include <errno.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>

/*
 * Programme de test ultra-basique : deux threads fils attendent avec P
 * et le thread principal réveille l'un des threads fils avec un V.
 * Normalement, le programme ne devrait pas se terminer.
 */

#include "monsem.h"

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

#define NTHR 2

noreturn void usage(char *argv0)
{
    fprintf(stderr, "usage: %s\n", argv0);
    exit(1);
}

noreturn void raler(char *msg)
{
    perror(msg);
    exit(1);
}

void *f(void *a)
{
    monsem_t *s = a;

    printf("Thread %jd : avant P\n", (intmax_t)pthread_self());
    CHK(monsem_P(s));
    printf("Thread %jd : après P\n", (intmax_t)pthread_self());
    return NULL;
}

int main(int argc, char *argv[])
{
    int i;
    monsem_t s;
    pthread_t tid[NTHR];

    if (argc != 1)
        usage(argv[0]);

    printf("Le programme ne doit pas s'arrêter, il faut faire ^C\n");

    CHK(monsem_init(&s, 0));
    for (i = 0; i < NTHR; i++)
        TCHK(pthread_create(&tid[i], NULL, f, &s));

    sleep(1);

    CHK(monsem_V(&s));

    // avec un seul V, le programme ne doit jamais se terminer.
    // s'il se termine, ce n'est pas bon.

    for (i = 0; i < NTHR; i++)
        TCHK(pthread_join(tid[i], NULL));

    exit(0);
}
