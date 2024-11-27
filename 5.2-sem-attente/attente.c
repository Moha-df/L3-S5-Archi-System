#include <errno.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

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
    fprintf(stderr, "usage: %s nb-threads\n", argv0);
    exit(1);
}

typedef struct
{
    sem_t *sem;
    int numT;
} Targs;

void *fonction(void *arg)
{
    Targs *targs = (Targs *)arg;
    sem_t *sem = targs->sem;  // Récupérer le sémaphore passé comme argument
    int moi = targs->numT;   // Utiliser l'ID du thread pour identifier ce thread

    printf("thread %d : je dors\n", moi);

    // TODO attendre l'événement transmis par le thread principal
    sem_wait(sem);

    printf("thread %d : ah... bien dormi !\n", moi);

    return NULL;
}

int main(int argc, char *argv[])
{
    int nthr;

    if (argc != 2)
        usage(argv[0]);

    nthr = atoi(argv[1]);
    if (nthr <= 0)
        usage(argv[0]);

    sem_t sem;
    sem_init(&sem, 0, 0);  // Initialiser le sémaphore à 0 pour que les threads attendent

    pthread_t threads[nthr];
    Targs targs[nthr]; // Créer un tableau de structures pour chaque thread

    
    for (int i = 0; i < nthr; i++)
    {
        targs[i].sem = &sem;      // Passer le sémaphore aux threads
        targs[i].numT = i;        // Passer l'ID du thread
       CHK(pthread_create(&threads[i], NULL, fonction, (void *)&targs[i]));
    }

    // attendre un caractère sur l'entrée standard (ou plus exactements
    // attendre le premier caractère d'une ligne complète)
    (void)getchar();
    printf("allez, debout !\n");

    // TODO réveiller les threads en attente
    // Libérer le sémaphore pour réveiller tous les threads
    for (int i = 0; i < nthr; i++)
    {
        sem_post(&sem);
    }

    for (int i = 0; i < nthr; i++)
    {
        CHK(pthread_join(threads[i], NULL));
    }

    printf("terminé\n");

    sem_destroy(&sem);


    exit(0);
}
