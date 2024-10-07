#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <errno.h>

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s val pos\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    unsigned long temp_val;
    char *endptr;
    uint32_t val;
    int pos;
    uint32_t partie_haute, partie_basse;

    if (argc != 3)
        usage(argv[0]);

    // Conversion de l'argument val
    temp_val = strtoul(argv[1], &endptr, 0);

    // Vérifier si la conversion s'est faite correctement
    if (*endptr != '\0') {
        fprintf(stderr, "Erreur : val doit être un entier valide.\n");
        exit(1);
    }

    // Vérifier les erreurs de dépassement
    if (temp_val == ULONG_MAX && errno == ERANGE) {
        fprintf(stderr, "Erreur : val dépasse la capacité maximale de uint32_t.\n");
        exit(1);
    }

    // Vérifier si temp_val est trop grand pour être stocké dans un uint32_t
    if (temp_val > UINT32_MAX) {
        fprintf(stderr, "Erreur : val doit être un entier non négatif et ne pas dépasser %u.\n", UINT32_MAX);
        exit(1);
    }

    val = (uint32_t)temp_val;

    // Conversion de la position
    pos = atoi(argv[2]);

    // Vérifier si la position est valide (entre 1 et 31)
    if (pos < 1 || pos > 31) {
        fprintf(stderr, "Erreur : pos doit être comprise entre 1 et 31.\n");
        exit(1);
    }

    // Calculer la partie haute (bits de 31 à pos)
    partie_haute = val >> pos;

    // Calculer la partie basse (bits de pos-1 à 0)
    uint32_t masque = (1U << pos) - 1;  // Générer un masque avec pos bits à 1
    partie_basse = val & masque;

    // Afficher les résultats
    printf("0x%x 0x%x\n", partie_haute, partie_basse);

    return 0;
}
