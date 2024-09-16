#define BIB_MAGIC 0x42494221 // identifie un fichier "bibliothèque"

/*
 * On met l'en-tête dans une structure pour pouvoir éventuellement,
 * un jour futur (pas dans cet exercice) ajouter des éléments
 */

struct entete
{
    int magic; // devrait être le numéro magique
    // éventuellement d'autres informations pourraient être mises ici
};

/*
 * Définition d'un livre dans la bibliothèque
 */

#define MAX_TITRE 10

struct livre
{
    int nbpages;               // doit être > 0 s'il y a un livre
    char titre[MAX_TITRE + 1]; // +1 pour le '\0' de fin de chaîne
};

/*
 * La structure complète de la bibliothèque est définie par la
 * structure ci-dessous. On notera que le tableau des livres
 * est un "flexible array member" (cf. cours)
 */

struct bibli
{
    struct entete e;
    struct livre l[]; // flexible array member
};
