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
    fprintf(stderr, "usage: %s t n1 n2\n", argv0);
    exit(1);
}

// attend un délai aléatoire borné par tmax ms
void attente_aleatoire(int tmax, unsigned int *seed)
{
    useconds_t delai;
    delai = tmax * (rand_r(seed) / ((double)RAND_MAX + 1));
    usleep(delai * 1000);
}

void *passager(void *arg)
{
    int num_passager; // numéro du passager [0 ... n1+n2-1]
    int tmax;         // durée max des temps d'attente
    unsigned int seed;
    // un passager arrière s'installe
    attente_aleatoire(tmax, &seed);
    printf("Parriere %d est installe\n", num_passager);
    // un passager avant s'installe
    attente_aleatoire(tmax, &seed);
    printf("Pavant %d est installe\n", num_passager);
    // tout le monde est installé
    printf("P %d : on peut decoller !\n", num_passager);

    return NULL;
}

int main(int argc, char *argv[])
{
    int tmax, n1, n2;
    unsigned int seed;
    // l'hôtesse attend que l'avion soit prêt
    attente_aleatoire(tmax, &seed);
    printf("Hotesse : on embarque\n");
    // Les passagers peuvent embarquer
    // ça y est, tout le monde est installé
    printf("Avion decolle\n");

    exit(0);
}
