#include <ctype.h>
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <unistd.h>

/*
 * Compiler avec :
 * - -DUNIQUE : un seul mutex pour protéger les accès aux 4 compteurs globaux
 * - -DGLOBAL : 4 mutex distincts pour protéger individuellement
 *      chaque compteur global
 * - -DLOCAL : 4 compteurs locaux, ajout des valeurs une seule fois à la fin
 */

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
    fprintf(stderr, "usage: %s fichier ...\n", argv0);
    exit(1);
}

#if !defined(UNIQUE) && !defined(GLOBAL) && !defined(LOCAL)
#error Il faut compiler avec -DUNIQUE, -DGLOBAL ou -DLOCAL
#endif

// 4 compteurs globaux
unsigned long int n_alnum = 0;
unsigned long int n_punct = 0;
unsigned long int n_space = 0;
unsigned long int n_other = 0;

#ifdef LOCAL
typedef struct
{
    unsigned long int alnum;
    unsigned long int punct;
    unsigned long int space;
    unsigned long int other;
} Counters;

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

void *analyser_fichier(void *arg)
{
    FILE *file = (FILE *)arg;
    int c;
    Counters local = {0, 0, 0, 0};

    // Lire chaque caractère du fichier
    while ((c = fgetc(file)) != EOF)
    {
        if (isalnum(c))
            local.alnum++;
        else if (ispunct(c))
            local.punct++;
        else if (isspace(c))
            local.space++;
        else
            local.other++;
    }

    // Mettre à jour les compteurs globaux
    pthread_mutex_lock(&mutex);
    n_alnum += local.alnum;
    n_punct += local.punct;
    n_space += local.space;
    n_other += local.other;
    pthread_mutex_unlock(&mutex);

    fclose(file); // Fermeture ici

    return NULL;
}

#endif

#ifdef GLOBAL
pthread_mutex_t mutex_alnum = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex_punct = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex_space = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t mutex_other = PTHREAD_MUTEX_INITIALIZER;

void *analyser_fichier(void *arg)
{
    FILE *file = (FILE *)arg;
    int c;

    // Lire chaque caractère du fichier
    while ((c = fgetc(file)) != EOF)
    {
        if (isalnum(c))
        {
            pthread_mutex_lock(&mutex_alnum);
            n_alnum++;
            pthread_mutex_unlock(&mutex_alnum);
        }
        else if (ispunct(c))
        {
            pthread_mutex_lock(&mutex_punct);
            n_punct++;
            pthread_mutex_unlock(&mutex_punct);
        }
        else if (isspace(c))
        {
            pthread_mutex_lock(&mutex_space);
            n_space++;
            pthread_mutex_unlock(&mutex_space);
        }
        else
        {
            pthread_mutex_lock(&mutex_other);
            n_other++;
            pthread_mutex_unlock(&mutex_other);
        }
    }
    fclose(file); // Fermeture ici

    return NULL;
}
#endif



#ifdef UNIQUE
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

void *analyser_fichier(void *arg)
{
    FILE *file = (FILE *)arg;
    int c;

    // Lire chaque caractère du fichier
    while ((c = fgetc(file)) != EOF)
    {
        // Protéger les accès aux compteurs
        pthread_mutex_lock(&mutex);

        if (isalnum(c))
            n_alnum++;
        else if (ispunct(c))
            n_punct++;
        else if (isspace(c))
            n_space++;
        else
            n_other++;

        // Déverrouiller le mutex
        pthread_mutex_unlock(&mutex);
    }

    fclose(file); // Fermeture ici

    return NULL;
}
#endif





// Les mutex peuvent aussi être globaux pour simplifier

int main(int argc, char *argv[])
{
    if (argc == 1)
        usage(argv[0]);

    pthread_t *threads = malloc((argc - 1) * sizeof(pthread_t));
    if (threads == NULL){
        raler("malloc");
    }
        
    
    for (int i = 1; i < argc; i++)
    {
        FILE *file = fopen(argv[i], "r");
        if (file == NULL)
        {
            fprintf(stderr, "arg pas un fichier");
            exit(1);
            continue;
        }

        #if defined(UNIQUE) || defined(GLOBAL) || defined(LOCAL)
         if (pthread_create(&threads[i - 1], NULL, analyser_fichier, file) != 0)
        {
            perror("pthread_create");
            fclose(file);
            continue;
        }

        #endif

    }


    #if defined(UNIQUE) || defined(GLOBAL) || defined(LOCAL)
    for (int i = 0; i < argc - 1; i++)
    {
        pthread_join(threads[i], NULL);
    }
    #endif


    // Afficher les résultats
    printf("%lu %lu %lu %lu \n", n_alnum, n_punct, n_space, n_other);
    
    free(threads);


    exit(0);
}
