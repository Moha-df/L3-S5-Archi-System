#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>

#include "stock.h"

#define SLOW_DELAY 3 // Délai entre opérations sur 2 articles différents

/*
 * Ajoute ou retire une ou plusieurs unités d'un ou plusieurs articles.
 * (un seul source compilé avec -DAJOUT ou -DRETRAIT)
 *
 * L'appel "ajout [--slow] ref qte [ref qte...]" (respectivement
 * "retrait [--slow] ref qte [ref qte...]") ajoute (respectivement
 * retire) la quantité donnée pour chaque référence. Il appelle
 * d'abord la fonction stock_map(). Puis pour chaque couple
 * (référence, quantité) il détermine l'article concerné à l'aide de
 * la fonction stock_findref(), et agit de façon appropriée sur le
 * sémaphore associé à l'article. Enfin, il appelle stock_unmap().
 *
 * Il ignore les arguments qui ne comportent pas des références
 * valides, sans s'arrêter à la première référence invalide.
 *
 * L'argument optionnel "--slow" (ou "-s") impose un délai de durée
 * SLOW_DELAY entre le traitement de deux articles.
 */

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s [--slow] ref qte [ref qte...]\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    int slow = 0;
    int first = 1;
    if (argc > first &&
        (strcmp(argv[first], "-s") == 0 || strcmp(argv[first], "--slow") == 0))
    {
        slow = 1;
        ++first;
    }
    if (argc <= first + 1 || (argc - first) % 2 != 0)
        usage(argv[0]);

    struct stock *stock = stock_map();
    for (int i = first; i < argc; i += 2)
    {
        int ref, qte, r;

        ref = atoi(argv[i]);
        qte = atoi(argv[i + 1]);
        if (ref <= 0 || ref == NULLREF || qte <= 0)
            usage(argv[0]);

#if defined(AJOUT)
        r = stock_add(stock, ref, qte);
#elif defined(RETRAIT)
        r = stock_rem(stock, ref, qte);
#else
#error "Il faut compiler avec -DAJOUT ou -DRETRAIT"
#endif
        if (!r)
        {
            fprintf(stderr, "Référence %d inconnue, ignorée\n", ref);
            exit(1);
        }

        if (slow)
            sleep(SLOW_DELAY);
    }
    stock_unmap(stock);

    exit(0);
}
