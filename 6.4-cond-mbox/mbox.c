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
    fprintf(stderr, "usage: %s t p nr ne\n", argv0);
    exit(1);
}

// attend un délai aléatoire borné par tmax ms
void attente_aleatoire(int tmax, unsigned int *seed)
{
    useconds_t delai;
    delai = tmax * (rand_r(seed) / ((double)RAND_MAX + 1));
    usleep(delai * 1000);
}

// la boîte aux lettres avec ses mécanismes de synchronisation
struct mbox
{
    int msg; // le message à transmettre (= 1 ici)
};

void *emetteur(void *arg)
{
    unsigned int seed;
    int tmax, p;

    for (int i = 0; i < p; i++)
    {
        // attendre un délai aléatoire
        attente_aleatoire(tmax, &seed);

        // attendre que la boîte aux lettres soit libre

        // déposer le message
        m->msg = 1;

        // indiquer aux récepteurs qu'ils peuvent consulter la boîte
    }

    // prévenir que j'ai fini

    return NULL;
}

void *recepteur(void *arg)
{
    unsigned int seed;
    int numthr; // numéro du thread
    int tmax;
    int nbmsg; // nb de messages reçus

    // attendre un événement, le traiter, et attendre

    // bilan des messages reçus par ce thread
    printf("T%d : nb recus = %d\n", numthr, nbmsg);

    return NULL;
}

int main(int argc, char *argv[])
{
    int tmax, p, ne, nr;
    int n;

    if (argc != 5)
        usage(argv[0]);

    tmax = atoi(argv[1]);
    p = atoi(argv[2]);
    ne = atoi(argv[3]);
    nr = atoi(argv[4]);
    if (tmax < 0 || p < 0 || ne < 1 || nr < 1)
        usage(argv[0]);

    n = ne + nr;

    exit(0);
}
