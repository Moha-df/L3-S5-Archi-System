#include <errno.h>
#include <pthread.h>
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
    fprintf(stderr, "usage: %s\n", argv0);
    exit(1);
}

void tache(int i)
{
    // sleep (1);               // pour déboguer
    printf("%d\n", i);
}


int main(int argc, char *argv[])
{
    if (argc != 1)
        usage(argv[0]);


    pthread_t threads;

    pthread_create(&threads, NULL, tache, (void*)1);


    pthread_join(threads, NULL);


    exit(0);
}
