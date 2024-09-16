//////////////////////////////////////////////////////////////////////////////

// Définitions globales du système
#define CR_MAX          10      // max 10 coroutines, de 0 à 9
#define CR_STACKSIZE    100     // nb de mots dans la pile de chaque coroutine

.addr   1000

//////////////////////////////////////////////////////////////////////////////
// Programme de test simple :
//////////////////////////////////////////////////////////////////////////////

// main_simple () {
//      cr_init () ;            // devient maintenant coroutine 0
//      a = 123 ;               // pour vérifier le passage par cr_simple
//      cr_create (cr_simple) ;
//      cr_yield () ;           // attendre le yield() de la coroutine 1
//      b = canari ;
//      reset ;                 // fin normale : A=123, B=456
// }
//
// int canari = 789 ;
//
// cr_simple () {       // corooutine 1
//      canari = 456 ;
//      cr_yield () ;
//      // on ne doit jamais arriver ici
//      reset
// }

main_simple:
        call cr_init
        ld   cr_simple,%a
        call cr_create          // cr_create (cr_simple)
        ld   123,%a
        call cr_yield
        ld   [canari],%b
        // résultat attendu à la fin normale : a=123, b=456
        reset

cr_simple:
        ld   456,%a
        st   %a,[canari]
        call cr_yield
        // on ne devrait pas arriver ici
        ld   9999,%b
        reset

canari:
        .word 789               // doit être écrasé par la coroutine

//////////////////////////////////////////////////////////////////////////////
// Programme de test complexe :
//////////////////////////////////////////////////////////////////////////////

// main_complexe () {
//      cr_init () ;            // devient maintenant coroutine 0
//      cr_create (cr_complexe1) ;
//      cr_create (cr_complexe1) ;
//      cr_create (cr_complexe2) ;
//      b = 0 ;
//      while (cr_count () > 1) {
//              b++ ;           // compter les yield de la coroutine 0
//              cr_yield () ;
//      }
//      a = mc_cpt ;
//      reset ;                 // fin normale : A=N1+N2+N3, B=max(N1,N2,N3)+1
// }
//
// #define N1 ...
// #define N2 ...
// #define N3 ...
//
// cr_complexe1 () {            // coroutines 1 et 2
//      cr_complexe_commun ((cr_id() == 1) ? N1 : N2) ;
// }
// cr_complexe2 () {            // coroutine 3
//      cr_complexe_commun (N3) ;
// }
//
// int mc_cpt = 0 ;             // variable globale
//
// cr_complexe_commun (a) {
//      while (a > 0) {
//              mc_cpt++ ;
//              cr_yield () ;
//              a-- ;
//      }
// }

// nb de cr_yield() pour chacune des trois coroutines
#define N1      2
#define N2      3
#define N3      5

main_complexe:
        call cr_init
        // créer 3 nouvelles coroutines, 2 avec complexe1, 1 avec complexe2
        ld   cr_complexe1,%a
        call cr_create
        ld   cr_complexe1,%a
        call cr_create
        ld   cr_complexe2,%a
        call cr_create
        // attendre la fin des co-routines :
        // b = 0
        // while (cr_count() > 1) { b++ ; cr_yield () ;
        ld   0,%b
        jmp  _mc_loop1end
_mc_loop1begin:
        add  1,%b
        // cette instruction ne sert qu'au debug, pour vérifier qu'on a
        // bien la même valeur au retour de cr_yield()
        ld   12345,%a
        call cr_yield
        // on devrait avoir 12345 dans A au retour
_mc_loop1end:
        call cr_count
        cmp  1,%a
        jlt  _mc_loop1begin
        ld   [mc_cpt],%a
        // a = nb total de yield par les coroutines 1 à 3 = N1+N2+N3
        // b = nb de yield par la coroutine 0
        // résultat attendu à la fin normale : a=N1+N2+N3, b=max(N1,N2,N3)+1
        reset

mc_cpt: .word 0                 // compteur du nb de yield par les 3 coroutines

cr_complexe1:
        // a = (cr_id() == 1) ? N1 : N2 ;
        call cr_id
        cmp  1,%a
        jne  _cr_complexe1_cr2
        // coroutine 1
        ld   N1,%a
        jmp  cr_complexe_commun
_cr_complexe1_cr2:
        // coroutine 2
        ld   N2,%a
        jmp  cr_complexe_commun

cr_complexe2:
        ld   N3,%a

cr_complexe_commun:
        // compter le nb total de yield effectués par les 3 coroutines
        // while (a > 0) { mc_cpt++ ; cr_yield () ; a-- ; }
        cmp  0,%a
        jge  cr_complexe_fin
        // mc_cpt++
        ld   [mc_cpt],%b
        add  1,%b
        st   %b,[mc_cpt]
        // cr_yield ()
        call cr_yield
        // a--
        sub  1,%a
        jmp  cr_complexe_commun
cr_complexe_fin:
        call cr_exit

        // on est censé ne plus rien exécuter à partir d'ici
        ld   9999,%a
        reset

//////////////////////////////////////////////////////////////////////////////
// Programme de test d'attente
//////////////////////////////////////////////////////////////////////////////

// main_attente () {
//      cr_init () ;            // devient maintenant coroutine 0
//      cr_create (cr_boucle) ;
//      cr_create (cr_attente) ;
//      cr_create (cr_boucle) ;
//      cr_yield () ;           // laisser coroutine 2 le temps de démarrer
//      cr_wakeup (2) ;
//      cr_sleep () ;           // attendre le réveil par coroutine 2
//      a = cr_count () ;       // il devrait en rester 3 à la fin
//      b = mc_att ;            // vérifier que cr_attente a tout bien fait
//      reset ;                 // fin normale : A=3, B=456
// }
//
// cr_boucle () {       // coroutines 1 et 3
//      // ne s'arrête jamais, les yield() sont là pour perturber le système
//      for (;;) cr_yield () ;
// }
//
// int mc_att = 0 ;
// 
// cr_attente () {      // coroutine 2
//      cr_sleep () ;           // attendre réveil par coroutine 0
//      mc_att = 123 ;
//      cr_yield () ;
//      mc_wakeup (0) ;         // réveiller coroutine 0
//      mc_att = 456 ;
//      mc_exit () ;
// }

main_attente:
        call cr_init
        ld   cr_boucle,%a
        call cr_create
        ld   cr_attente,%a
        call cr_create
        ld   cr_boucle,%a
        call cr_create
        call cr_yield
        ld   2,%a
        call cr_wakeup
        call cr_sleep
        call cr_count
        ld   [mc_att],%b
        // résultat attendu à la fin normale : a=3, b=456
        reset

mc_att: .word 0

cr_boucle:
        call cr_yield
        jmp cr_boucle

cr_attente:
        call cr_sleep
        ld   123,%a
        st   %a,[mc_att]
        call cr_yield
        ld   0,%a
        call cr_wakeup
        ld   456,%a
        st   %a,[mc_att]
        call cr_exit
        // on ne devrait jamais arriver là
        ld   99999,%b
        reset


//////////////////////////////////////////////////////////////////////////////
// Implémentation des coroutines
//////////////////////////////////////////////////////////////////////////////


.addr   8000
// début des adresses des piles des coroutines
cr_stack:
        .space          CR_MAX * CR_STACKSIZE

.addr   3000

// Aucun argument en entrée, aucune valeur particulière en retour
cr_init:
        rtn

// Entrée : A = adresse du code de la coroutine
// Pas de valeur de retour particulière, et pas d'obligation de restaurer B.
cr_create:
        rtn

// Aucun argument en entrée
// En sortie, A = numéro de la coroutine active
// Pas d'obligation de restaurer B.
cr_id:
        rtn

// Aucun argument en entrée
// En sortie, A = nombre de coroutines actives
// Pas d'obligation de restaurer B.
cr_count:
        rtn

// Aucun argument en entrée. En sortie, les registres sont restaurés
// tels qu'ils étaient avant l'appel
cr_yield:
        rtn


// Aucun argument en entrée. Le retour se passe dans une coroutine active.
cr_exit:

// Aucun argument en entrée. En sortie, les registres sont restaurés
// tels qu'ils étaient avant l'appel
cr_sleep:

// Entrée : A = numéro de la coroutine à réveiller
// Pas d'obligation de restaurer B.
cr_wakeup:
