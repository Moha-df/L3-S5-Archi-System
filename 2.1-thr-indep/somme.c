#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    long int thread_num; 
    long int p;
    long int *result; 
} thread_data_t;


void *calculate_sum(void *arg) {
    thread_data_t *data = (thread_data_t *)arg;
    long int t = data->thread_num;
    long int p = data->p;

    long int ut = 0;
    for (long int i = 1; i <= p; i++) {
        ut += (t - 1) * p + i;
    }

    *data->result = ut;
    pthread_exit(NULL);
}

int main(int argc, char *argv[])
{
    long int n, p;
    long int somme = 0;

    if(argc != 3){
        fprintf(stderr, "usage : %s <n> <p>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    n = atoi(argv[1]);
    p = atoi(argv[2]);

    if (n < 1 || p < 1) {
        fprintf(stderr, "usage : %s <n> <p>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    pthread_t threads[n];
    long int results[n]; 
    thread_data_t thread_data[n];

    for (long int t = 1; t <= n; t++) {
        thread_data[t - 1].thread_num = t;
        thread_data[t - 1].p = p;
        thread_data[t - 1].result = &results[t - 1];

        if (pthread_create(&threads[t - 1], NULL, calculate_sum, &thread_data[t - 1]) != 0) {
            fprintf(stderr, "Erreur de création du thread %ld\n", t);
            exit(EXIT_FAILURE);
        }
    }

    for (long int t = 0; t < n; t++) {
        pthread_join(threads[t], NULL);
    }

    for (long int t = 0; t < n; t++) {
        somme += results[t];
    }


    



    printf("%ld\n", somme);
    printf("(attendu : %ld)\n", n * p * (n * p + 1) / 2);

    exit(0);
}
