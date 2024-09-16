#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>

#include "stock.h"

/*
 * Création/destruction/affichage d'un stock projeté en mémoire.
 *
 * Ce programme contrôle un stock projetable dans un segment de
 * mémoire partagée. Ce contrôle prend trois formes.
 *
 * L'appel "ctrl init <nref>" crée un segment contenant un stock
 * pouvant contenir <nref> articles. Il appelle la fonction
 * stock_create(), puis stock_unmap().
 *
 * L'appel "ctrl unlink" demande la destruction du segment de mémoire
 * partagée. Il appelle la fonction stock_unlink().
 *
 * L'appel "ctrl dump" affiche le contenu brut du segment. Il appelle
 * successivement stock_map(), stock_dump() et stock_unmap().
 */

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage:  %s init nb-réf\n", argv0);
    fprintf(stderr, "        %s destroy\n", argv0);
    fprintf(stderr, "        %s dump\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    if (argc == 3 && strcmp(argv[1], "init") == 0)
    {
        int n;
        n = atoi(argv[2]);
        if (n <= 0)
            usage(argv[0]);
        struct stock *stock = stock_create(n);
        stock_unmap(stock);
    }
    else if (argc == 2 && strcmp(argv[1], "destroy") == 0)
    {
        struct stock *stock = stock_map();
        stock_destroy(stock);
    }
    else if (argc == 2 && strcmp(argv[1], "dump") == 0)
    {
        struct stock *stock = stock_map();
        stock_dump(stock, stdout);
        stock_unmap(stock);
    }
    else if (argc == 2 && strcmp(argv[1], "map") == 0)
    {
        struct stock *stock = stock_map();
        char cmd[128];
        (void)snprintf(cmd, sizeof cmd, "cat /proc/%d/maps", getpid());
        // cette commande ne fonctionne que sur Linux (cf. "man 5 proc")
        system(cmd);
        stock_unmap(stock);
    }
    else
        usage(argv[0]);

    exit(0);
}
