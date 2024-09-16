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
    fprintf(stderr, "usage: %s t n p\n", argv0);
    exit(1);
}

// attend un délai aléatoire borné par max ms
void attente_aleatoire(int max, unsigned int *seed)
{
    useconds_t delai;
    delai = max * (rand_r(seed) / ((double)RAND_MAX + 1));
    usleep(delai * 1000);
}

void *bavard(void *arg)
{
    int numthr; // numéro du thread [0...n-1]
    int g, d;   // baguette de gauche, de droite
    unsigned int seed;
    int tmax; // durée max aléatoire
    printf("%d parle\n", numthr);
    attente_aleatoire(tmax, &seed);
    printf("%d premiere baguette (%d), parle\n", numthr, g);
    attente_aleatoire(tmax, &seed);
    printf("%d seconde baguette (%d), mange\n", numthr, d);
    attente_aleatoire(tmax, &seed);
    return NULL;
}

int main(int argc, char *argv[])
{
    int n, p, t;

    if (argc != 4)
        usage(argv[0]);
    t = atoi(argv[1]);
    n = atoi(argv[2]);
    p = atoi(argv[3]);
    if (t < 0 || n <= 1 || p < 0)
        usage(argv[0]);

    exit(0);
}
