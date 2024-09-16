#include <errno.h>
#include <pthread.h>
#include <semaphore.h>
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
    fprintf(stderr, "usage: %s nb-chaises nb-clients\n", argv0);
    exit(1);
}

int nbchaises; // global et invariable

void *coiffeur(void *arg)
{
    (void)arg;
    for (;;) // le coiffeur ne termine jamais
    {
        printf("je coiffe\n");
        sleep(5);
    }
}

void *client(void *arg)
{
    (void)arg;
    printf("je me fais coiffer\n");
    return NULL;
}

int main(int argc, char *argv[])
{
    int nbclients;

    if (argc != 3)
        usage(argv[0]);

    nbchaises = atoi(argv[1]); // var globale
    nbclients = atoi(argv[2]);
    if (nbchaises <= 0 || nbclients <= 0)
        usage(argv[0]);

    // lancer le thread coiffeur

    srand(1);
    /* on lance des clients à intervalle irrégulier */
    for (int i = 0; i < nbclients; i++)
    {
        sleep(1 + (rand() % 3));
        // lancer un thread client
    }

    // attendre la fin de tous les clients, mais pas du coiffeur
    printf("done\n");
    exit(0);
}
