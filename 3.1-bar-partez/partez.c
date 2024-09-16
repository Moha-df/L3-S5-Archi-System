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
    fprintf(stderr, "usage: %s n\n", argv0);
    exit(1);
}

void *thread(void *arg)
{
    int numthr = -1; // à modifier
    int elu = 0;     // par défaut : personne n'est élu

    printf("Thread %d%s\n", numthr, elu ? ", je suis élu" : "");

    return NULL;
}

int main(int argc, char *argv[])
{
    int n;

    if (argc != 2)
        usage(argv[0]);
    n = atoi(argv[1]);
    if (n < 0)
        usage(argv[0]);

    // prêt ? attendre une ligne (éventuellement vide)
    printf("Saisie au clavier : ");
    (void)getchar();

    // partez !

    // à n'afficher que lorsqu'on attendu que tous les threads soient terminés
    printf("Terminé\n");

    exit(0);
}
