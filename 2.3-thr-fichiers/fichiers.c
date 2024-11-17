#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdint.h>
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

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

#define BUFSIZE 4096

// Structure pour passer les données au thread
typedef struct
{
    const char *filename;
    off_t nalpha;
    double blank;
} FileData;

// Fonction exécutée par chaque thread
void *process_file(void *arg)
{
    FileData *data = (FileData *)arg;
    int fd = open(data->filename, O_RDONLY);
    CHK(fd);

    char buffer[BUFSIZE];
    ssize_t bytes_read;
    off_t total_chars = 0;
    off_t alpha_count = 0;
    off_t blank_count = 0;

    while ((bytes_read = read(fd, buffer, BUFSIZE)) > 0)
    {
        for (ssize_t i = 0; i < bytes_read; i++)
        {
            total_chars++;
            if (isalpha(buffer[i]))
                alpha_count++;
            if (isblank(buffer[i]))
                blank_count++;
        }
    }
    CHK(bytes_read);
    CHK(close(fd));

    data->nalpha = alpha_count;
    data->blank = total_chars > 0 ? (double)blank_count / total_chars : 0;

    return NULL;
}

int main(int argc, char *argv[])
{
    pthread_t threads[argc - 1];
    FileData file_data[argc - 1];

    // Création d'un thread pour chaque fichier
    for (int i = 0; i < argc - 1; i++)
    {
        file_data[i].filename = argv[i + 1];
        pthread_create(&threads[i], NULL, process_file, &file_data[i]);
    }

    // Attente de la fin de chaque thread
    for (int i = 0; i < argc - 1; i++)
    {
        pthread_join(threads[i], NULL);
        printf("%s %jd %.5lf\n", file_data[i].filename, (intmax_t)file_data[i].nalpha, file_data[i].blank);
    }

    return 0;
}
