#include <fcntl.h>
#include <semaphore.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

/*
 * Compiler sans rien pour voir l'interblocage se produire
 *      (visible seulement avec un très grand nombre de repas, par ex 10000)
 * Compiler sans -DNOINTERB pour une version sans interblocage et sans attente
 *      de terminaison
 * Compiler avec -DTERMINAISON pour que table attende que le dernier
 *      philosophe ait quitté la table
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
    fprintf(stderr, "usage: %s nrepas\n", argv0);
    exit(1);
}

/*
 * Il faudrait mettre la définition dans un fichier .h séparé pour mutualiser
 * avec table.c (pas fait ici pour diminuer le nombre de fichiers)
 */

#define MEMNAME "/table"

int main(int argc, char *argv[])
{
    int nrepas;

    if (argc != 2)
        usage(argv[0]);

    nrepas = atoi(argv[1]);
    if (nrepas <= 0)
        usage(argv[0]);

    exit(0);
}
