#include <ctype.h>
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <unistd.h>

/*
 * Compiler avec :
 * - -DUNIQUE : un seul mutex pour protéger les accès aux 4 compteurs globaux
 * - -DGLOBAL : 4 mutex distincts pour protéger individuellement
 *      chaque compteur global
 * - -DLOCAL : 4 compteurs locaux, ajout des valeurs une seule fois à la fin
 */

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
    fprintf(stderr, "usage: %s fichier ...\n", argv0);
    exit(1);
}

#if !defined(UNIQUE) && !defined(GLOBAL) && !defined(LOCAL)
#error Il faut compiler avec -DUNIQUE, -DGLOBAL ou -DLOCAL
#endif

// 4 compteurs globaux
unsigned long int n_alnum = 0;
unsigned long int n_punct = 0;
unsigned long int n_space = 0;
unsigned long int n_other = 0;

// Les mutex peuvent aussi être globaux pour simplifier

int main(int argc, char *argv[])
{
    if (argc == 1)
        usage(argv[0]);

    exit(0);
}
