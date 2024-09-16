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

int m, p, tmax; // on utilise les notations de l'énoncé

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

noreturn void usage(const char *argv0)
{
    fprintf(stderr,
            "usage: %s m n p tmax\n"
            "\tm = nb mach, n = nb ut, p = nb jobs, "
            "tmax = borne sup durée job (en ms)\n",
            argv0);
    exit(1);
}

// tire un nombre pseudo-aléatoire dans [0,max] avec une graine "seed"
int alea(int max, unsigned int *seed)
{
    int r;

    r = max * (rand_r(seed) / (double)RAND_MAX);
    return r;
}

// simule un job
void job(int u, int j, int kuj, int t)
{
    printf("user %d job %d machines %d duration %d ms\n", u, j, kuj, t);
    fflush(stdout);

    usleep(t * 1000); // conversion ms -> us

    printf("fin user %d job %d\n", u, j);
    fflush(stdout);
}

int main(int argc, char *argv[])
{
    int n;

    if (argc != 5)
        usage(argv[0]);

    m = atoi(argv[1]);
    n = atoi(argv[2]);
    p = atoi(argv[3]);
    tmax = atoi(argv[4]);
    if (m < 1 || n < 1 || p < 0 || tmax < 0)
        usage(argv[0]);

    exit(0);
}
