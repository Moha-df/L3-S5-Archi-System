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

// Structure pour stocker les arguments de chaque thread
typedef struct {
    int delai;  // Délai en millisecondes
    int numero; // Numéro du thread
    pthread_cond_t *cond;  // Condition pour signaler la fin du délai
    pthread_mutex_t *mutex; // Mutex pour protéger la condition
    int can_terminate;
} thread_arg_t;

void *fonction(void *arg)
{
    // TODO mon numéro de thread (1..n)
    // TODO l'attente qui m'a été communiquée par le thread principal
    thread_arg_t *params = (thread_arg_t *)arg;
    int delai = params->delai;
    int numero = params->numero;
    pthread_cond_t *cond = params->cond;
    pthread_mutex_t *mutex = params->mutex;

    usleep(delai * 1000);
    printf("T %d fin usleep\n", numero);

    // TODO envoyer l'information au thread principal
    // Signaler que le thread a terminé son attente
    pthread_mutex_lock(mutex);
    params->can_terminate = 1;
    pthread_cond_signal(cond);
    pthread_mutex_unlock(mutex);

    printf("T %d terminé\n", numero);
    return NULL;
}

int main(int argc, char *argv[])
{
    setbuf(stdout, NULL); // ne pas bufferiser les affichages

    if (argc == 1)
        usage(argv[0]);

    // TODO tester la validité des arguments, puis créer les threads
    // les tests doivent être effectués avant de commencer les créations


    // Nombre de threads à créer (n)
    int n = argc - 1;
    int delais[n];

    // Lecture des délais à partir des arguments
    for (int i = 0; i < n; i++) {
        delais[i] = atoi(argv[i + 1]);
        if (delais[i] <= 0) {
            usage(argv[0]);
        }
    }

    // Initialisation du mutex et des conditions
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    pthread_cond_t cond = PTHREAD_COND_INITIALIZER;

    pthread_t threads[n];
    thread_arg_t args[n];

    // Créer les threads
    for (int i = 0; i < n; i++) {
        args[i].delai = delais[i];
        args[i].numero = i + 1;
        args[i].cond = &cond;
        args[i].mutex = &mutex;
        args[i].can_terminate = 0;
        TCHK(pthread_create(&threads[i], NULL, fonction, &args[i]));
    }

    // TODO attendre la fin des usleep de tous les threads
    // À chaque fois qu'un thread nous notifie sa fin d'attente,
    // il faut faire :
    //          printf ("P reçu T %d terminé\n", ....) ;
    // (avec le bon numéro de thread)

    // Attente que tous les threads terminent leur délai
    for (int i = 0; i < n; i++) {
        pthread_mutex_lock(&mutex);
        while(!args[i].can_terminate){
            pthread_cond_wait(&cond, &mutex); // Attendre que le thread i termine son délai
        }
        printf("P reçu T %d termine\n", i + 1);
        pthread_mutex_unlock(&mutex);
    }

    // TODO attendre la terminaison des threads
    // Attendre la terminaison de tous les threads
    for (int i = 0; i < n; i++) {
        TCHK(pthread_join(threads[i], NULL));
    }

    printf("P terminé\n");

    exit(0);
}
