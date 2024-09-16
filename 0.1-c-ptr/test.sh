#!/bin/sh

PROG=${PROG:=./calc}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# teste une opération
# $1 = a
# $2 = op
# $3 = b
# $4 = valeur attendue
tester_op ()
{
    [ $# != 4 ] && fail "ERREUR SYNTAXE tester_op"
    local a="$1" op="$2" b="$3" att="$4"

    $PROG "$a" "$op" "$b" > $TMP.out 2> $TMP.err || fail "échec $a $op $b"
    verifier_stdout
    echo "$att" | diff - $TMP.out > $TMP.diff \
    	|| fail "résultat != attendu pour '$a $op $b' (cf $TMP.out et $TMP.diff)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "pas assez d'arguments" && {
    $PROG 1 +   > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
}

run_test 1.2 "trop d'arguments" && {
    $PROG 1 + 1 + > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.1 "add" && {
    tester_op 3 + 4 7
    tester_op 18 + 5 23
    tester_op -2 + 5 3
}

run_test 2.2 "add" && {
    tester_op 15 - 6 9
    tester_op 12 - -8 20
}

run_test 2.3 "mul" && {
# "*" étant un caractère spécial du shell, il faut le neutraliser
    tester_op 3 "*" 5 15
    tester_op 9 "*" -7 -63
}

run_test 2.4 "div" && {
    tester_op 18 / 2 9
    tester_op 17 / -2 -8
}

run_test 2.5 "mod" && {
    tester_op 22 % 5 2
    tester_op -18 % 7 -4
}

run_test 2.6 "shift left" && {
# "<" étant un caractère spécial du shell, il faut le neutraliser
    tester_op 16 "<<" 2 64
    tester_op 19 "<<" 1 38 		# 32 + 4 + 2
}

run_test 2.7 "shift right" && {
# ">" étant un caractère spécial du shell, il faut le neutraliser
    tester_op 64 ">>" 3 8
    tester_op 131 ">>" 2 32
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    nettoyer
    tester_valgrind $PROG 3 + 4
}
