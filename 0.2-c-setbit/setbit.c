#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s val bit [0-ou-1]\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    unsigned long temp_val;
    char *endptr;
    uint32_t val;
    int bit;
    int OneOrZero;

    if (argc != 3 && argc != 4)
        usage(argv[0]);

    // Vérifier si le premier argument est négatif
    if (argv[1][0] == '-') {
        fprintf(stderr, "Erreur : val < 0\n");
        exit(1);
    }

    // Utilisation de strtoul avec endptr pour détecter les erreurs d'entrée non numérique
    temp_val = strtoul(argv[1], &endptr, 0);

    // Vérifier si la conversion s'est faite correctement
    if (*endptr != '\0') {
        fprintf(stderr, "Erreur : val doit être un entier valide.\n");
        exit(1);
    }

    // Vérifie si strtoul a produit un dépassement
    if (temp_val == ULONG_MAX && errno == ERANGE) {
        fprintf(stderr, "Erreur : val dépasse la capacité maximale de uint32_t.\n");
        exit(1);
    }

    // Vérifie si temp_val est trop grand pour être stocké dans un uint32_t
    if (temp_val > UINT32_MAX) {
        fprintf(stderr, "Erreur : val doit être un entier non négatif et ne pas dépasser %u.\n", UINT32_MAX);
        exit(1);
    }

    val = (uint32_t)temp_val;

    bit = atoi(argv[2]);

    if (bit < 0 || bit > 31) {
        fprintf(stderr, "Le bit doit être compris entre 0 et 31.\n");
        exit(1);
    }

    if (argc == 3) {
        // Afficher le bit de val à la position "bit"
        printf("%d\n", (val >> bit) & 1); // Décale val et masque pour obtenir le bit
        return 0;
    }

    if (argc == 4) {
        // ici on set le bit de val a la position "bit" a OneOrZero
        OneOrZero = atoi(argv[3]);

            // Vérification si OneOrZero est bien 0 ou 1
        if (OneOrZero != 0 && OneOrZero != 1) {
            fprintf(stderr, "Erreur : le troisième argument doit être 0 ou 1.\n");
            exit(1);
        }

        if (OneOrZero == 1) {
            val |= (1U << bit);
        } else {
            val &= ~(1U << bit);
        }
        printf("%u 0x%x\n", val, val);

        return 0;
    }

    exit(0);
}
