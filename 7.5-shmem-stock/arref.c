#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

#include "stock.h"

/*
 * Ajout/retrait d'un article dans le stock projeté en mémoire.
 * (un seul source compilé avec -DAJOUT ou -DRETRAIT)
 *
 * L'appel "aref ref [ref...]" crée dans le stock autant de nouveaux
 * articles qu'il reçoit d'arguments. Il appelle la fonction
 * stock_map(), puis pour chaque argument il appelle la fonction
 * stock_addref(), et enfin appelle la fonction stock_unmap(). Il
 * ignore les arguments qui ne sont pas des références valides, sans
 * s'arrêter à la première référence invalide.
 *
 * L'appel "rref ref [ref...] procède de manière similaire, mais
 * tente de supprimer, avec la fonction #stock_remref(), chaque
 * référence passée en argument.
 */

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s ref [ref...]\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    if (argc <= 1)
        usage(argv[0]);

    struct stock *stock = stock_map();

    for (int i = 1; i < argc; i++)
    {
        int r, ref;
        ref = atoi(argv[i]);
        if (ref <= 0)
            usage(argv[0]);

#if defined(AJOUT)
        r = stock_addref(stock, ref);
#elif defined(RETRAIT)
        r = stock_remref(stock, ref);
#else
#error "Il faut compiler avec -DAJOUT ou -DRETRAIT"
#endif
        if (!r)
        {
            fprintf(stderr, "Référence %d ne peut être ajoutée\n", ref);
            exit(1);
        }
    }
    stock_unmap(stock);

    exit(0);
}
