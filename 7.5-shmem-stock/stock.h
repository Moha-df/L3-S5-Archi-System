/*
 * Fichier contenant les définitions communes à toute ou partie
 * des fichiers sources de l'exercice.
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

// Valeur par défaut d'un référence pour un article non-initialisé
#define NULLREF ((~0U) >> 1)

// Indice de cellule inexistante, (<=> NULL pour les indices de cellule)
#define NULLPTR -1

// Représentation d'un article dans le stock
struct article
{
    int suiv;  // Indice de l'article suivant dans le chaînage (voir stock)
    int ref;   // Référence de l'article
    sem_t sem; // Sémaphore représentant la quantité disponible
};

// Représentation d'un stock complet
struct stock
{
    // Taille du segment complet, en octets. Utile pour munmap
    size_t taille;
    // Indice de la première cellule occupée, début d'une liste chaînée
    int occupes;
    // Indice de la première cellule libre, début d'une liste chaînée
    int libres;
    /*
     * Tableau des articles. C'est un "flexible array member", dont
     * la taille n'est pas déterminée à la compilation, mais au
     * moment de l'allocation/création (voir STOCK_SIZE pour le
     * calcul)
     */
    struct article articles[];
};

/*
 * Nom du segment de mémoire partagée. Doit être un nom valide pour
 * shm_open(). Sur Linux, le segment est visible comme un fichier
 * dans le répertoire /dev/shm.
 * S'il y a plusieurs utilisateurs sur la machine, il peut être
 * intéressant d'utiliser le nom "/<votre-login>.magasin" par exemple.
 */
#define STOCK_NAME "/magasin"

/*
 * Calcul de la taille d'une structure "struct stock", donc d'un
 *  segment de mémoire partagée contenant une telle structure
 */
#define STOCK_SIZE(nart) sizeof(struct stock) + (nart) * sizeof(struct article)

/*
 * Les fonctions suivantes sont documentées dans le fichier stock.c.
 */

noreturn void raler(const char *msg);

struct stock *stock_create(int nart);
struct stock *stock_map(void);
void stock_unmap(struct stock *stock);
void stock_destroy(struct stock *stock);

void stock_dump(struct stock *, FILE *fd);
void stock_list(struct stock *stock);

int stock_findref(struct stock *stock, int ref);
int stock_addref(struct stock *stock, int ref);
int stock_remref(struct stock *stock, int ref);

int stock_add(struct stock *stock, int ref, int qte);
int stock_rem(struct stock *stock, int ref, int qte);
