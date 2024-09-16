#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

#include "stock.h"

/*
 * Affichage des articles du stock projeté en mémoire.
 *
 * L'appel "liste" (sans argument) affiche la liste des articles du
 * stock. Il appelle la fonction stock_map(), puis stock_list(), et
 * enfin stock_unmap().
 */

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    struct stock *stock;

    if (argc != 1)
        usage(argv[0]);

    stock = stock_map();
    stock_list(stock);
    stock_unmap(stock);

    exit(0);
}
