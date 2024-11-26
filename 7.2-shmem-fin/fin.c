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
#include <sys/wait.h>
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
    fprintf(stderr, "usage: %s fichier\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    if (argc != 2)
        usage(argv[0]);
    
    const char *file_path = argv[1];

    // Ouvrir le fichier
    int fd = open(file_path, O_RDONLY);
    CHK(fd);

    // Obtenir la taille du fichier
    struct stat st;
    CHK(fstat(fd, &st));

    size_t file_size = st.st_size;

    // Mapper le fichier en mémoire
    void *map = mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (map == MAP_FAILED)
        raler("mmap");

    // Fermer le fichier car il n'est plus nécessaire
    CHK(close(fd));

    ssize_t firstN = -1;

    // Parcourir le fichier en mémoire pour compter les occurrences
    const char *data = (const char *)map;

    for (ssize_t i = file_size-2; i >= 0; i--){   
        if (data[i] == '\n'){
            firstN = i;
            break;
        }
    }

    if (firstN == -1) // le cas ou on a trouver aucun \n
    {
        for (ssize_t i = 0; i < (ssize_t)file_size; i++)
        {
            printf("%c", data[i]);
        }
    }
    else // le cas ou on a trouver un \n
    {
        for (ssize_t i = firstN + 1; i < (ssize_t)file_size; i++)
        {
            printf("%c", data[i]);
        }
    }

    // Démapper la mémoire
    CHK(munmap(map, file_size));



    exit(0);
}
