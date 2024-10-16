#!/bin/sh

#
# On reprend le script de test de l'exercice initial (avec et sans mutex)
# en élaguant la partie sans mutex.
#

#PROG=${PROG:=./thr}			# chemin de l'exécutable
PROG2=${PROG2:=./thr-sem}

# lire les variables et fonctions communes
. ../test-inc.sh

OBJ=$((40*1000*1000))			# objectif = 40 millions

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments thr-sem" && {
    $PROG2 1        > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 1.2 "resultat thr-sem" && {
    lancer_timeout 15 $PROG2
    verifier_stdout
    total=$(cat $TMP.out)
    [ $total != $OBJ ]		&& fail "thr-sem devrait donner $OBJ (et non $total)"
}

##############################################################################
# Test valgrind

run_test 2.1 "valgrind thr-sem" 15 && {
    tester_valgrind $PROG2
}
