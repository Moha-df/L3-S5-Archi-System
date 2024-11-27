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

        #ifdef UNIQUE

         if (pthread_create(&threads[i - 1], NULL, analyser_fichier, file) != 0)
        {
            perror("pthread_create");
            fclose(file);
            continue;
        }

        #endif

    }


    #ifdef UNIQUE
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
