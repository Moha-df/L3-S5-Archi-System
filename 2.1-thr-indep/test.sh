#!/bin/sh

PROG=${PROG:=./somme}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifier la sortie
# $1 : résultat attendu
verifier_sortie ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local att="$1"

    verifier_stdout
    v=$(head -1 $TMP.out)
    [ x"$v" = x"$att" ]		|| fail "résultat ($v) != attendu ($att)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments" && {
    $PROG 1     > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
    nettoyer
    $PROG 1 1 1 > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.2 "arguments invalides" && {
    $PROG -1 2    > $TMP.out 2> $TMP.err	&& fail "n=-1 invalide"
    verifier_stderr
    $PROG 0 2     > $TMP.out 2> $TMP.err	&& fail "n=0 invalide"
    verifier_stderr
    nettoyer
    $PROG 2 -1    > $TMP.out 2> $TMP.err	&& fail "p=-1 invalide"
    verifier_stderr
    nettoyer
    $PROG 2 0     > $TMP.out 2> $TMP.err	&& fail "p=0 invalide"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "somme 3 4" && {
    $PROG 3 4 > $TMP.out 2> $TMP.err || fail "erreur d'exécution"
    verifier_sortie 78
}

run_test 2.2 "somme 2000 1000" && {
    $PROG 2000 1000 > $TMP.out 2> $TMP.err || fail "erreur d'exécution"
    verifier_sortie 2000001000000
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 3 4
}
