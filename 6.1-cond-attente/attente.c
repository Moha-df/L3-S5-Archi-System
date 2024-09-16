#include <errno.h>
#include <pthread.h>
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

noreturn void usage(char *argv0)
{
    fprintf(stderr, "usage: %s delai1 delai2\n", argv0);
    exit(1);
}

struct argument
{
    int d2;
    // TODO il faut sans doute ajouter d'autres champs à cette structure
};

void *fonction(void *arg)
{
    struct argument *a = arg;

    usleep(a->d2 * 1000);
    printf("T2 fin usleep\n");

    // TODO attendre le signal du thread principal

    printf("T2 terminé\n");
    return NULL;
}

int main(int argc, char *argv[])
{
    int d1, d2;
    pthread_t tid;
    struct argument arg;

    setbuf(stdout, NULL); // ne pas bufferiser les affichages

    if (argc != 3)
        usage(argv[0]);

    d1 = atoi(argv[1]);
    if (d1 < 0)
        usage(argv[0]);

    d2 = atoi(argv[2]);
    if (d2 < 0)
        usage(argv[0]);

    arg.d2 = d2;
    // TODO il faut sans doute d'autres initialisations

    TCHK(pthread_create(&tid, NULL, fonction, &arg));

    usleep(d1 * 1000);
    printf("T1 fin usleep\n");

    // TODO indiquer à T2 qu'il peut se terminer

    printf("T1 attente terminaison T2\n");
    TCHK(pthread_join(tid, NULL));

    printf("T1 terminé\n");

    exit(0);
}
