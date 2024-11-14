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

// Structure pour contenir les informations d'un utilisateur
typedef struct {
    int m;           // Nombre de machines disponibles
    int n;           // Nombre d'utilisateurs
    int p;           // Nombre de jobs par utilisateur
    int tmax;        // Durée maximale d'un job
    pthread_mutex_t mutex;  // Mutex pour protéger l'accès aux machines
    pthread_cond_t cond;    // Condition pour synchroniser les utilisateurs
} center_t;

// Fonction d'erreur
noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

// Fonction d'affichage de l'utilisation
noreturn void usage(const char *argv0)
{
    fprintf(stderr,
            "usage: %s m n p tmax\n"
            "\tm = nb mach, n = nb ut, p = nb jobs, "
            "tmax = borne sup durée job (en ms)\n",
            argv0);
    exit(1);
}

// tire un nombre pseudo-aléatoire dans [0,max] avec une graine "seed"
int alea(int max, unsigned int *seed)
{
    int r;
    r = max * (rand_r(seed) / (double)RAND_MAX);
    return r;
}

// Simule un job
void job(int u, int j, int kuj, int t)
{
    printf("user %d job %d machines %d duration %d ms\n", u, j, kuj, t);
    fflush(stdout);
    usleep(t * 1000); // Conversion ms -> us
    printf("fin user %d job %d\n", u, j);
    fflush(stdout);
}

// Fonction exécutée par chaque utilisateur (thread)
void *utilisateur(void *arg)
{
    center_t *center = (center_t *)arg;
    int u = *((int *)arg + sizeof(center_t)/sizeof(int));
    unsigned int seed = u;  // Initialisation de la graine pour chaque utilisateur

    for (int j = 0; j < center->p; j++) {
        int kuj = alea(center->m, &seed) + 1;  // Nombre de machines nécessaires pour le job
        int job_time = alea(center->tmax, &seed);  // Durée du job (entre 0 et tmax ms)

        printf("user %d waiting for %d machines for job %d\n", u, kuj, j);

        // Attendre que suffisamment de machines soient disponibles
        pthread_mutex_lock(&center->mutex);
        while (kuj > center->m) {
            pthread_cond_wait(&center->cond, &center->mutex);  // Attente si pas assez de machines
        }

        center->m -= kuj;  // Réserver les machines
        pthread_mutex_unlock(&center->mutex);

        job(u, j, kuj, job_time);  // Exécuter le job

        // Libérer les machines
        pthread_mutex_lock(&center->mutex);
        center->m += kuj;  // Libérer les machines
        pthread_cond_broadcast(&center->cond);  // Notifier tous les threads que des machines sont disponibles
        pthread_mutex_unlock(&center->mutex);
    }

    return NULL;
}

int main(int argc, char *argv[])
{
    if (argc != 5)
        usage(argv[0]);

    // Initialiser le centre de calcul
    center_t center;
    center.m = atoi(argv[1]);
    center.n = atoi(argv[2]);
    center.p = atoi(argv[3]);
    center.tmax = atoi(argv[4]);

    if (center.m < 1 || center.n < 1 || center.p < 0 || center.tmax < 0)
        usage(argv[0]);

    pthread_mutex_init(&center.mutex, NULL);  // Initialisation du mutex
    pthread_cond_init(&center.cond, NULL);    // Initialisation de la condition

    pthread_t *threads = malloc(center.n * sizeof(pthread_t));  // Tableau des threads
    int *ids = malloc(center.n * sizeof(int));  // Identifiants des utilisateurs

    // Créer les threads pour chaque utilisateur
    for (int i = 0; i < center.n; i++) {
        ids[i] = i;
        TCHK(pthread_create(&threads[i], NULL, utilisateur, &center));
    }

    // Attendre que tous les threads se terminent
    for (int i = 0; i < center.n; i++) {
        TCHK(pthread_join(threads[i], NULL));
    }

    // Libérer les ressources
    free(threads);
    free(ids);

    pthread_mutex_destroy(&center.mutex);  // Détruire le mutex
    pthread_cond_destroy(&center.cond);    // Détruire la condition

    printf("Tous les jobs sont terminés.\n");

    return 0;
}
