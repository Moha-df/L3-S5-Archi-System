#!/bin/sh

PROG=${PROG:=./thr}			# chemin de l'exécutable
PROG2=${PROG2:=./thrmutex}

# lire les variables et fonctions communes
. ../test-inc.sh

OBJ=$((40*1000*1000))			# objectif = 40 millions

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments thr" && {
    $PROG 1        > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 1.2 "resultat thr" && {
    lancer_timeout 5 $PROG
    verifier_stdout
    total=$(cat $TMP.out)
    [ $total -lt $OBJ ]		|| fail "thr devrait donner un résultat < $OBJ"
}

##############################################################################
# Test valgrind

run_test 1.3 "valgrind thr" && {
    tester_valgrind $PROG
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 2.1 "nb d'arguments thrmutex" && {
    $PROG2 1        > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.2 "resultat thrmutex" && {
    lancer_timeout 10 $PROG2
    verifier_stdout
    total=$(cat $TMP.out)
    [ $total != $OBJ ]	&& fail "thrmutex devrait donner $OBJ (et non $total)"
}

##############################################################################
# Test valgrind

run_test 2.3 "valgrind thrmutex" 10 && {
    tester_valgrind $PROG2
}

##############################################################################
# Comparaison des performances

run_test 3.1 "comparaison des performances" 10 && {
    $TIME -p $PROG  > /dev/null 2> $TMP.time1
    t1=$(duree $TMP.time1)
    $TIME -p $PROG2 > /dev/null 2> $TMP.time2
    t2=$(duree $TMP.time2)
# la durée de $PROG2 devrait être au moins le triple de celle de $PROG
    [ $t2 -ge $((3 * t1)) ]		|| fail "$PROG2 est trop rapide par rapport à $PROG : vérifiez que vous n'avez pas transformé un programme parallèle en programme séquentiel..."
}
