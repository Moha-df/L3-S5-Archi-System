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

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s n\n", argv0);
    exit(1);
}

typedef struct {
    int num_thread;           // Numéro du thread
    int *elu;                 // Indique quel thread est élu
    pthread_barrier_t *bar;   // Barrière de synchronisation
} ThreadArg;

void *thread(void *arg)
{
    ThreadArg *targ = (ThreadArg *)arg;

    // Attendre le signal du départ
    pthread_barrier_wait(targ->bar);


    printf("Thread %d%s\n", targ->num_thread, targ->elu ? ", je suis élu" : "");

    return NULL;
}

int main(int argc, char *argv[])
{
    int n;

    if (argc != 2)
        usage(argv[0]);
    n = atoi(argv[1]);
    if (n < 0)
        usage(argv[0]);

    pthread_t threads[n];
    ThreadArg args[n];
    pthread_barrier_t bar;
    int elu;

    // Initialiser la barrière pour n threads
    if (pthread_barrier_init(&bar, NULL, n + 1) != 0) {
        raler("pthread_barrier_init");
    }

    // Générer un numéro aléatoire pour l'élu
    srand(time(NULL));
    elu = rand() % n;

    // Créer les threads
    for (int i = 0; i < n; i++) {
        args[i].num_thread = i;
        args[i].elu = 0;
        if(i==elu){args[i].elu = &elu;}
        args[i].bar = &bar;

        if (pthread_create(&threads[i], NULL, thread, &args[i]) != 0) {
            raler("pthread_create");
        }
    }

    // prêt ? attendre une ligne (éventuellement vide)
    printf("Saisie au clavier : ");
    (void)getchar();

    // Libérer les threads via la barrière
    pthread_barrier_wait(&bar);

    // Attendre la fin de tous les threads
    for (int i = 0; i < n; i++) {
        if (pthread_join(threads[i], NULL) != 0) {
            raler("pthread_join");
        }
    }

        // Détruire la barrière
    pthread_barrier_destroy(&bar);
    free(threads);


    // à n'afficher que lorsqu'on attendu que tous les threads soient terminés
    printf("Terminé\n");

    exit(0);
}
