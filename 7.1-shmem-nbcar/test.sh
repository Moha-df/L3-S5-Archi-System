#!/bin/sh

PROG=${PROG:=./nbcar}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie du programme est correcte
# $1 = fichier cherché
# $2 = caractère cherché
verifier_sortie ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local in="$1" car="$2"
    local natt nout

    verifier_stdout

    # comparer d'abord les tailles pour avoir un résultat lisible
    natt=$(tr -d -C "$car" < "$in" | wc -c)
    nout=$(cat "$TMP.out")
    [ x"$natt" != x"$nout" ] \
	&& fail "Valeur trouvée ($nout) incorrecte (devrait être $natt)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "pas assez d'arguments" && {
    echo coucou > $TMP.in
    $PROG $TMP.in > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
}

run_test 1.2 "trop d'arguments" && {
    echo coucou > $TMP.in
    $PROG $TMP.in 1 2 > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.3 "argument n'est pas un fichier" && {
    $PROG $TMP.nonexistant > $TMP.out 2> $TMP.err && fail "fichier inexistant"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "test basique" && {
    echo "coucou les cousins chéris" > $TMP.in
    $PROG $TMP.in c > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie $TMP.in c
}

run_test 2.2 "gros fichier" && {
    for i in $(seq 100)
    do
        cat /usr/include/stdio.h
    done >> $TMP.in
    $PROG $TMP.in i > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie $TMP.in i
}

run_test 2.3 "données aléatoires" && {
    generer_fichier_aleatoire $TMP.in 4
    $PROG $TMP.in x > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie $TMP.in x
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    echo abc > $TMP.in
    tester_valgrind $PROG $TMP.in a
}
