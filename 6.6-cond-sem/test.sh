#!/bin/sh

# on ne teste pas ex3th

PROG=${PROG:=./cat2th}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie est correcte
# $1 = fichier d'entrée
verifier_sortie ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local in="$1"

    local tin tout
# comparer d'abord les tailles pour avoir un résultat lisible
    tin=$(wc -c < $in)
    tout=$(wc -c < $TMP.out)
    [ $tin != $tout ] \
	&& fail "Tailles différentes : $in:$tin $TMP.out:$tout"

# le résultat de cmp est parfois difficile à interpréter
    cmp $in $TMP.out > $TMP.cmp 2> $TMP.err \
	|| fail "Résultat != attendu (cf $in, $TMP.out et $TMP.cmp)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments" && {
    $PROG 1 > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.1 "petit transfert" && {
    echo abcd > $TMP.in
    lancer_timeout 2 $PROG < $TMP.in	|| fail "erreur cat2th, cf $TMP.err"
    verifier_sortie $TMP.in
}

run_test 2.2 "gros transfert" && {
    generer_fichier_aleatoire $TMP.in 1
    lancer_timeout 20 $PROG < $TMP.in	|| fail "erreur cat2th, cf $TMP.err"
    verifier_sortie $TMP.in
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    echo abcd > $TMP.in
    tester_valgrind $PROG < $TMP.in
    verifier_sortie $TMP.in
}
