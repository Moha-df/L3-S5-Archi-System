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

typedef struct {
    int progression;
    int duree1pcent;
    pthread_mutex_t mutex;
} Avancement;

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s durée-1%%-en-ms\n", argv0);
    exit(1);
}

// une tâche très lente (enfin, c'est fonction de l'argument du programme)
void *tache(void *arg)
{
    Avancement *avancement = (Avancement *)arg;
    while (1) {
        usleep(avancement->duree1pcent * 1000);  // Conversion de miliseconde en microsecondes
        TCHK(pthread_mutex_lock(&avancement->mutex));
        if (avancement->progression >= 100) {
            pthread_mutex_unlock(&avancement->mutex);
            break;
        }
        avancement->progression++;
        pthread_mutex_unlock(&avancement->mutex);
    }
    return NULL;
}

// thread : affiche l'avancement et se termine lorsqu'il atteint 100 %
void *gui(void *arg)
{
    Avancement *avancement = (Avancement *)arg;
    while (1) {
        sleep(1);  // Affiche chaque seconde
        TCHK(pthread_mutex_lock(&avancement->mutex));
        printf("%d %%\n", avancement->progression);
        if (avancement->progression >= 100) {
            pthread_mutex_unlock(&avancement->mutex);
            break;
        }
        pthread_mutex_unlock(&avancement->mutex);
    }
    return NULL;
}

int main(int argc, char *argv[])
{
    if (argc != 2)
        usage(argv[0]);

    int duree1pcent = atoi(argv[1]);
    if (duree1pcent <= 0)
        usage(argv[0]);

    Avancement avancement = { .progression = 0, .duree1pcent = duree1pcent };
    TCHK(pthread_mutex_init(&avancement.mutex, NULL));

    pthread_t tache_thread, gui_thread;
    TCHK(pthread_create(&tache_thread, NULL, tache, &avancement));
    TCHK(pthread_create(&gui_thread, NULL, gui, &avancement));

    TCHK(pthread_join(tache_thread, NULL));
    TCHK(pthread_join(gui_thread, NULL));

    printf("termine\n");

    pthread_mutex_destroy(&avancement.mutex);
    exit(0);
}
