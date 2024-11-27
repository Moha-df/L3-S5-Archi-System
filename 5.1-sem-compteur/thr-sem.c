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
    fprintf(stderr, "usage: %s\n", argv0);
    exit(1);
}

#define TOURS 10 * 1000 * 1000
#define NTHREAD 4

long int compteur; // compteur global

sem_t sem; // Sémaphore pour exclusion mutuelle



void* func(){
    for (int i = 0; i < TOURS; i++) {
        sem_wait(&sem);  // Prendre le sémaphore (entrer dans la section critique)
        compteur++;
        sem_post(&sem);  // Libérer le sémaphore (sortir de la section critique)
    }
    return NULL;
}

int main(int argc, char *argv[])
{
    pthread_t tid[NTHREAD];

    if (argc != 1)
        usage(argv[0]);

    // Initialisation du sémaphore
    sem_init(&sem, 0, 1);  // 1 est la valeur initiale du sémaphore

    pthread_create(&tid[0], NULL, func, NULL);
    pthread_create(&tid[1], NULL, func, NULL);
    pthread_create(&tid[2], NULL, func, NULL);
    pthread_create(&tid[3], NULL, func, NULL);

    pthread_join(tid[0], NULL);
    pthread_join(tid[1], NULL);
    pthread_join(tid[2], NULL);
    pthread_join(tid[3], NULL);

    printf("%ld\n", compteur);

    sem_destroy(&sem);

    exit(0);
}
