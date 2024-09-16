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
    fprintf(stderr, "usage: %s delai1 delai2 ... delainN\n", argv0);
    exit(1);
}

void *fonction(void *arg)
{
    int moi, delai;

    // TODO mon numéro de thread (1..n)
    moi = 0;
    // TODO l'attente qui m'a été communiquée par le thread principal
    delai = 0;

    usleep(delai * 1000);
    printf("T %d fin usleep\n", moi);

    // TODO envoyer l'information au thread principal

    printf("T %d terminé\n", moi);
    return NULL;
}

int main(int argc, char *argv[])
{
    setbuf(stdout, NULL); // ne pas bufferiser les affichages

    if (argc == 1)
        usage(argv[0]);

    // TODO tester la validité des arguments, puis créer les threads
    // les tests doivent être effectués avant de commencer les créations

    // TODO attendre la fin des usleep de tous les threads
    // À chaque fois qu'un thread nous notifie sa fin d'attente,
    // il faut faire :
    //          printf ("P reçu T %d terminé\n", ....) ;
    // (avec le bon numéro de thread)

    // TODO attendre la terminaison des threads

    printf("P terminé\n");

    exit(0);
}
