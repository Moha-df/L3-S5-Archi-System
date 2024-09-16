#include <fcntl.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
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

#include "bibli.h"

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s bibliothèque titre\n", argv0);
    exit(1);
}

noreturn void erreur(const char *msg)
{
    fprintf(stderr, "%s\n", msg);
    exit(1);
}

int main(int argc, char *argv[])
{
    if (argc != 3)
        usage(argv[0]);

    char *biblio, *titre;

    biblio = argv[1];
    titre = argv[2];
    if (strlen(titre) > MAX_TITRE)
        erreur("titre trop long");

    exit(0);
}
