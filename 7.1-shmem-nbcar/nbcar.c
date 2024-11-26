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

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s fichier caractère\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    off_t n = 0; // nombre de caractères trouvés

    if (argc != 3)
        usage(argv[0]);

    const char *file_path = argv[1];
    char target = argv[2][0]; // Le caractère à chercher

    // Ouvrir le fichier
    int fd = open(file_path, O_RDONLY);
    CHK(fd);

    // Obtenir la taille du fichier
    struct stat st;
    CHK(fstat(fd, &st));

    size_t file_size = st.st_size;

    // Mapper le fichier en mémoire
    void *map = mmap(NULL, file_size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
    if (map == MAP_FAILED)
        raler("mmap");

    // Fermer le fichier car il n'est plus nécessaire
    CHK(close(fd));

    // Parcourir le fichier en mémoire pour compter les occurrences
    const char *data = (const char *)map;
    for (size_t i = 0; i < file_size; i++)
    {
        if (data[i] == target)
            n++;
    }

    // Démapper la mémoire
    CHK(munmap(map, file_size));

    // Afficher le résultat
    printf("%jd\n", (intmax_t)n);

    exit(0);
}

