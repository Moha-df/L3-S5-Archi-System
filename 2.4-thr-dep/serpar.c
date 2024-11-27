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
    fprintf(stderr, "usage: %s\n", argv0);
    exit(1);
}

void tache(int i)
{
    // sleep (1);               // pour déboguer
    printf("%d\n", i);
}

void *execute_tache(void *arg)
{
    int t = *((int *)arg);
    tache(t);
    return NULL;
}


int main(int argc, char *argv[])
{
    if (argc != 1)
        usage(argv[0]);


    // Création des threads pour chaque tâche
    pthread_t threads[11];  // Il y a 11 tâches (1 à 42)
    int t1 = 1, t21 = 21, t22 = 22, t31 = 31, t32 = 32, t33 = 33, t41 = 41, t42 = 42, t5 = 5, t34 = 34;
    // Exécution des tâches dans l'ordre des dépendances

    // Tâche 1
    CHK(pthread_create(&threads[0], NULL, execute_tache, (void *)&t1));

    // Attendre que la tâche 1 soit terminée avant de lancer 21 et 22
    pthread_join(threads[0], NULL);
    // Tâches 21 et 22 après la tâche 1
    CHK(pthread_create(&threads[1], NULL, execute_tache, (void *)&t21));
    CHK(pthread_create(&threads[2], NULL, execute_tache, (void *)&t22));

    // Attendre que les tâches 21 soit terminées avant de lancer 31, 32, 33
    pthread_join(threads[1], NULL);
    // Tâches 31, 32, 33 après 21
    CHK(pthread_create(&threads[3], NULL, execute_tache, (void *)&t31));
    CHK(pthread_create(&threads[4], NULL, execute_tache, (void *)&t32));
    CHK(pthread_create(&threads[5], NULL, execute_tache, (void *)&t33));

    // Attendre que les tâches 22 soit terminées avant de lancer 34
    pthread_join(threads[2], NULL);
    CHK(pthread_create(&threads[6], NULL, execute_tache, (void *)&t34));

    // Attendre que 31, 32 et 33 soient terminées avant de lancer 41
    pthread_join(threads[3], NULL);
    pthread_join(threads[4], NULL);
    pthread_join(threads[5], NULL);
    // Tâches 41 après 31, 32, 33
    CHK(pthread_create(&threads[7], NULL, execute_tache, (void *)&t41));

    // Attendre que les tâches 34 soit terminées avant de lancer 42
    pthread_join(threads[6], NULL);
    CHK(pthread_create(&threads[8], NULL, execute_tache, (void *)&t42));

    // Attendre que les tâches 41 et 42 soient terminées avant de lancer la tâche 5
    pthread_join(threads[7], NULL);
    pthread_join(threads[8], NULL);
    // Tâche 5 après 41 et 42
    CHK(pthread_create(&threads[9], NULL, execute_tache, (void *)&t5));

    // Attendre que la tâche 5 soit terminée
    pthread_join(threads[9], NULL);


    exit(0);
}
