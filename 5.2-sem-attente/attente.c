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
    fprintf(stderr, "usage: %s nb-threads\n", argv0);
    exit(1);
}

void *fonction(void *arg)
{
    int moi;

    (void)arg; // TODO à supprimer
    moi = 0;   // TODO remplacer par le num de thread

    printf("thread %d : je dors\n", moi);
    // TODO attendre l'événement transmis par le thread principal
    printf("thread %d : ah... bien dormi !\n", moi);

    return NULL;
}

int main(int argc, char *argv[])
{
    int nthr;

    if (argc != 2)
        usage(argv[0]);

    nthr = atoi(argv[1]);
    if (nthr <= 0)
        usage(argv[0]);

    for (int i = 0; i < nthr; i++)
    {
        // TODO créer les threads
    }

    // attendre un caractère sur l'entrée standard (ou plus exactement
    // attendre le premier caractère d'une ligne complète)
    (void)getchar();
    printf("allez, debout !\n");

    // TODO réveiller les threads en attente

    for (int i = 0; i < nthr; i++)
    {
        // TODO attendre la terminaison des threads
    }

    printf("terminé\n");

    exit(0);
}
