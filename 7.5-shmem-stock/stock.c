#include <fcntl.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "stock.h"

#define NOTYET                                                                 \
    do                                                                         \
    {                                                                          \
        fprintf(stderr, "Not yet implemented (%s:%d)\n", __FILE__, __LINE__);  \
        exit(1);                                                               \
    } while (0)

noreturn void raler(const char *msg)
{
    perror(msg);
    exit(1);
}

/*
 * Création d'un segment de mémoire partagée contenant un stock.
 *
 * Cette fonction doit créer un nouveau segment de mémoire partagée
 * de nom STOCK_NAME (qui ne doit pas déjà exister). Ce segment doit
 * avoir une taille suffisante pour contenir le nombre d'articles
 * passé en paramètre.
 *
 * Cette fonction doit également initialiser le contenu du segment,
 * c'est-à-dire : la liste des cellules libres doit contenir toutes
 * les cellules, la liste des cellules occupées doit être une liste
 * vide, et chaque cellule doit contenir une référence égale à
 * NULLREF. Les sémaphores associés ne sont pas initialisés dans
 * cette fonction, mais au moment où la cellule devient occupée.
 *
 * nart : le nombre d'articles à conserver dans le stock.
 * retourne : l'adresse du nouveau segment, projeté en mémoire
 */

struct stock *stock_create(int nart)
{
    (void)nart;
    NOTYET;
}

/*
 * Projection en mémoire du segment de mémoire partagée.
 *
 * Le segment de nom STOCK_NAME est projeté en mémoire, et devient
 * accessible en lecture/écriture via le pointeur fourni en valeur de
 * retour. Le segment est partagé avec tous les autres processus qui
 * le projettent également en mémoire.
 *
 * retourne : l'adresse du segment existant, projeté en mémoire
 */

struct stock *stock_map(void)
{
    NOTYET;
    return NULL;
}

/*
 * Suppression de la projection en mémoire du segment de mémoire partagée.
 *
 * Après appel de cette fonction, le segment de mémoire n'est plus
 * accessible. Le contenu du segment n'est pas affecté par un appel à
 * cette fonction.
 *
 * stock : l'adresse du début de la projection fournie par
 * stock_create() ou stock_map().
 * retourne : cette fonction ne renvoie rien.
 */

void stock_unmap(struct stock *stock)
{
    (void)stock;
    NOTYET;
}

/*
 * Suppression du segment de mémoire partagée.
 *
 * Tous les sémaphores contenus dans le segment sont détruits à
 * l'aide de sem_destroy(). La projection est ensuite supprimée.
 * Enfin, le nom du segment (STOCK_NAME) est passé à shm_unlink().
 * Le segment sera effectivement détruit lorsque le dernier processus
 * qui le projette dans son espace d'adressage aura appelé
 * stock_unmap().
 *
 * stock : un pointeur vers le début de la projection.
 * retourne : cette fonction ne renvoie rien.
 */

void stock_destroy(struct stock *stock)
{
    (void)stock;
    NOTYET;
}

/*
 * Affichage du contenu brut du segment de mémoire partagée.
 *
 * Cette fonction affiche quelques renseignements sur le segment
 * projeté à l'adresse passée en premier argument, sur le descripteur
 * de fichier passé en second argument. Elle affiche également toutes
 * les cellules, ainsi que le contenu de la cellule lorsque celle-ci
 * est occupée.
 *
 * stock : un pointeur vers le début de la projection.
 * fd : le descripteur sur lequel écrire la description.
 * retourne : cette fonction ne renvoie rien.
 */

void stock_dump(struct stock *stock, FILE *fd)
{
    fprintf(fd, "ADRESSE DU SEGMENT %p\n", (void *)stock);
    fprintf(fd, "LIBRES %d OCCUPES %d\n", stock->libres, stock->occupes);
    size_t n = (stock->taille - sizeof(struct stock)) / sizeof(struct article);
    fprintf(fd,
            "|article|=%zu octets |stock|=%zu o size=%zu o"
            " -> %zu articles\n",
            sizeof(struct article), sizeof(struct stock), stock->taille, n);
    for (size_t i = 0; i < n; i++)
    {
        struct article *art = &(stock->articles[i]);

        // affichage du suivant dans la liste
        fprintf(fd, "%zd suiv %d", i, art->suiv);

        // affichage de l'article s'il existe
        if (art->ref == NULLREF)
            fprintf(fd, " vide"); // entrée vide, sans référence
        else
        {
            int v; // il y a une référence
            fprintf(fd, " réf %d", art->ref);
            CHK(sem_getvalue(&(art->sem), &v));
            fprintf(fd, " qté %d", v);
        }
        fprintf(fd, "\n");
    }
}

/*
 * Affichage des articles conservés dans le stock, avec leur quantité
 * disponible.
 *
 * Cette fonction parcourt les listes des cellules occupées, et pour
 * chaque cellule affiche la référence et la quantité de l'article
 * qui y est conservé.
 *
 * stock : un pointeur vers le début de la projection.
 * retourne : cette fonction ne renvoie rien.
 */

void stock_list(struct stock *stock)
{
    (void)stock;
    NOTYET;
}

/*
 * Recherche dans le stock d'un article par sa référence.
 *
 * Cette fonction parcourt dans le stock donné en premier argument la
 * listes des cellules occupées et recherche celle contenant
 * l'article ayant la référence donnée en second argument.
 *
 * Si l'article est présent, le numéro de la cellule qui le contient
 * est renvoyé. Si l'article n'est pas présent, la valeur NULLPTR
 * est renvoyée.
 *
 * stock : un pointeur vers le début de la projection.
 * ref : la référence d'article recherchée.
 * retourne : le numéro de la cellule contenant l'article, ou NULLPTR.
 */

int stock_findref(struct stock *stock, int ref)
{
    (void)stock;
    (void)ref;
    NOTYET;
    return NULLPTR;
}

/*
 * Ajoute un nouvel article dans le stock.
 *
 * Cette fonction ajoute dans le stock donnée en premier argument un
 * article dont la référence est le deuxième argument.
 *
 * Si l'article est déjà présent, cette fonction ne fait rien et
 * renvoie 0 (signifiant false).
 *
 * Sinon, si aucune cellule n'est disponible, cette fonction renvoie
 * 0 (signifiant false).
 *
 * Sinon, cette fonction réquisitionne une cellule libre. Elle place
 * dans cette cellule la référence passée en argument, et initialise
 * le sémaphore associé à la valeur zéro. Elle met correctement à
 * jour les deux listes chaînées du stock.
 *
 * stock : un pointeur vers le début de la projection.
 * ref : la référence du nouvel article.
 * retourne : un entier/booléen indiquant si l'article a bien été inséré.
 */

int stock_addref(struct stock *stock, int ref)
{
    (void)stock;
    (void)ref;
    NOTYET;
    return 0;
}

/*
 * Retire un article du stock.
 *
 * Cette fonction retire du stock donnée en premier argument un
 * article dont la référence est le deuxième argument.
 *
 * Si l'article n'est pas présent, cette fonction ne fait rien et
 * renvoie 0 (signifiant false).
 *
 * Sinon, cette fonction place NULLREF dans la référence de la
 * cellule contenant l'article, et appelle sem_destroy() sur le
 * sémaphore associé. Elle met correctement à jour les deux listes
 * chaînées du stock.
 *
 * stock : un pointeur vers le début de la projection.
 * ref : la référence de l'article à supprimer.
 * retourne : un entier/booléen indiquant si l'article a bien été retiré.
 */

int stock_remref(struct stock *stock, int ref)
{
    (void)stock;
    (void)ref;
    NOTYET;
    return 0;
}

/*
 * Augmente la quantité disponible d'un article dans le stock.
 *
 * Cette fonction modifie dans le stock donné en premier argument,
 * pour l'article dont la référence est donnée en deuxième argument,
 * la quantité disponible en lui ajoutant un nombre d'unités égal au
 * troisième argument.
 *
 * Si la référence n'est pas présente dans le stock, cette fonction
 * ne fait rien et renvoie 0. Sinon, elle appelle répétitivement
 * sem_post() sur le sémaphore associé à l'article, puis renvoie 1.
 *
 * stock : un pointeur vers le début de la projection.
 * ref : la référence de l'article.
 * qte : la quantité à ajouter, strictement positive.
 * retourne : 0 ou 1 selon que l'article existe ou non.
 */

int stock_add(struct stock *stock, int ref, int qte)
{
    (void)stock;
    (void)ref;
    (void)qte;
    NOTYET;
    return 0;
}

/*
 * Diminue la quantité disponible d'un article dans le stock.
 *
 * Cette fonction modifie dans le stock donné en premier argument,
 * pour l'article dont la référence est donnée en deuxième argument,
 * la quantité disponible en lui retirant un nombre d'unités égal au
 * troisième argument.
 *
 * Si la référence n'est pas présente dans le stock, cette fonction
 * ne fait rien et renvoie 0. Sinon, elle appelle répétitivement
 * sem_wait() sur le sémaphore associé à l'article, puis renvoie 1.
 *
 * Cette fonction est susceptible de rester bloquée en attente sur
 * chaque appel à sem_wait().
 *
 * stock : un pointeur vers le début de la projection.
 * ref : la référence de l'article.
 * qte : la quantité à ajouter, strictement positive.
 * retourne : 0 ou 1 selon que l'article existe ou non.
 */

int stock_rem(struct stock *stock, int ref, int qte)
{
    (void)stock;
    (void)ref;
    (void)qte;
    return 0;
}
