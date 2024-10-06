#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>

int f_add(int a, int b) { return a + b; }
int f_sub(int a, int b) { return a - b; }
int f_mul(int a, int b) { return a * b; }
int f_div(int a, int b) { return a / b; }
int f_mod(int a, int b) { return a % b; }
int f_shl(int a, int b) { return a << b; }
int f_shr(int a, int b) { return a >> b; }

// Définition de la structure op
struct op {
    const char *op_str; // Chaîne représentant l'opération
    int (*func)(int, int); // Pointeur vers la fonction correspondante
};

// Initialisation du tableau de structures op
struct op tabop[] = {
    {"+", f_add},
    {"-", f_sub},
    {"*", f_mul},
    {"/", f_div},
    {"%", f_mod},
    {"<<", f_shl},
    {">>", f_shr},
    {NULL, NULL} // Dernier élément pour indiquer une opération non trouvée
};

noreturn void usage(const char *argv0) {
    fprintf(stderr,
            "usage: %s entier op entier\n"
            "\top = +, -, *, /, %%, << ou >>\n"
            "\texemple : 2 + 3\n",
            argv0);
    exit(1);
}

int main(int argc, char *argv[]) {
    int a, b;
    const char *op; // Utiliser const char* pour le pointeur de l'opération
    int result = 0; // Pour stocker le résultat

    if (argc != 4) usage(argv[0]);

    a = atoi(argv[1]);
    b = atoi(argv[3]);
    op = argv[2];

    // Chercher l'opération et appeler la fonction correspondante sans indexation
    struct op *current = tabop; // Pointeur vers le début du tableau

    while (current->op_str != NULL) { // Tant que l'opération n'est pas NULL
        if (strcmp(op, current->op_str) == 0) {
            result = current->func(a, b); // Appel de la fonction correspondante
            printf("%d\n", result); // Affichage du résultat
            exit(0);
        }
        current++; // Avancer au prochain élément
    }

    // Si l'opération n'est pas trouvée, afficher l'usage
    usage(argv[0]);
}
