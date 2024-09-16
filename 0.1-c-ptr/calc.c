#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>

int f_add(int a, int b)
{
    return a + b;
}
int f_sub(int a, int b)
{
    return a - b;
}
int f_mul(int a, int b)
{
    return a * b;
}
int f_div(int a, int b)
{
    return a / b;
}
int f_mod(int a, int b)
{
    return a % b;
}
int f_shl(int a, int b)
{
    return a << b;
} // shift left
int f_shr(int a, int b)
{
    return a >> b;
} // shift right

/*
 * Cette structure doit contenir :
 * - une chaîne représentant l'opération (ex : "+" ou "<<")
 * - un pointeur sur la fonction correspondante (ex : "f_add" ou "f_shl")
 */

struct op
{
};

/*
 * Initialisation d'un tableau de struct op : toute l'initialisation
 * doit être réalisée ici , aucune autre initialisation ne doit être
 * réalisée dans le reste du programme.
 * Le dernier élément du tableau doit être initialisé de telle sorte
 * que "main" puisse s'arrêter si l'opération demandée n'est pas
 * trouvée.
 */

struct op tabop[] = {};

noreturn void usage(const char *argv0)
{
    fprintf(stderr,
            "usage: %s entier op entier\n"
            "\top = +, -, *, /, %%, << ou >>\n"
            "\texemple : 2 + 3\n",
            argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    int a, b;
    char *op;

    if (argc != 4)
        usage(argv[0]);

    a = atoi(argv[1]);
    b = atoi(argv[3]);
    op = argv[2];

    /*
     * Chercher l'opération et appeler la fonction correspondante
     * Note : il est interdit d'utiliser l'opérateur d'indexation
     * (ex : "tabop [...]") à partir d'ici.
     */

    exit(0);
}
