#!/bin/sh

PROG=${PROG:=./decoupe}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie du programme est correcte
# $1 = résultat attendu
verifier_sortie ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local att="$1"

    verifier_stdout
    echo "$att" | diff - $TMP.out > $TMP.diff \
    	|| fail "résultat = $(cat $TMP.out) différent de l'attendu ($att)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "pas assez d'arguments" && {
    $PROG 1   > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
}

run_test 1.2 "trop d'arguments" && {
    $PROG 1 2 1 > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.3 "arg val < 0" && {
    $PROG -1 0 > $TMP.out 2> $TMP.err	&& fail "val < 0"
    verifier_stderr
}

run_test 1.4 "arg val trop grand pour uint32_t" && {
# une valeur trop grande pour tenir dans un uint32_t
    $PROG 0x100000000 0 > $TMP.out 2> $TMP.err	&& fail "val déborde uint32_t"
    verifier_stderr
}

run_test 1.5 "arg val en décimal" && {
# en décimal, ça doit passer
    $PROG 0 1 > $TMP.out 2> $TMP.err || fail "décimal : erreur sur des arg simples"
    verifier_stdout
}

run_test 1.6 "arg val en hexadécimal" && {
# et en hexadécimal aussi
    $PROG 0x0 1 > $TMP.out 2> $TMP.err || fail "hexa : erreur sur des arg simples"
    verifier_stdout
}

run_test 1.7 "arg val invalide en décimal" && {
# test sur des valeurs invalides
    $PROG 0a 0 > $TMP.out 2> $TMP.err && fail "décimal : erreur sur des arg simples"
    verifier_stderr
}

run_test 1.8 "arg val invalide en hexadécimal" && {
# et en hexadécimal aussi
    $PROG 0x0x 0 > $TMP.out 2> $TMP.err && fail "hexa : erreur sur des arg simples"
    verifier_stderr
}

run_test 1.9 "arg pos < 0" && {
    $PROG 1 -1 > $TMP.out 2> $TMP.err	&& fail "bit < 0"
    verifier_stderr
}

run_test 1.10 "arg pos = 0" && {
    $PROG 1 0 > $TMP.out 2> $TMP.err	&& fail "bit == 0"
    verifier_stderr
}

run_test 1.11 "arg pos = 32" && {
    $PROG 1 -1 > $TMP.out 2> $TMP.err	&& fail "bit = 32"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "decoupe 0xffffffff 1" && {
    $PROG 0xffffffff 1 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x7fffffff 0x1"
}

run_test 2.2 "decoupe 0xffffffff 2" && {
    $PROG 0xffffffff 2 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x3fffffff 0x3"
}

run_test 2.3 "decoupe 0xffffffff 3" && {
    $PROG 0xffffffff 3 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x1fffffff 0x7"
}

run_test 2.4 "decoupe 0xffffffff 4" && {
    $PROG 0xffffffff 4 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0xfffffff 0xf"
}

run_test 2.5 "decoupe 0xffffffff 30" && {
    $PROG 0xffffffff 30 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x3 0x3fffffff"
}

run_test 2.6 "decoupe 0xffffffff 31" && {
    $PROG 0xffffffff 31 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x1 0x7fffffff"
}

run_test 2.7 "decoupe 0xdeadbeef 11" && {
    $PROG 0xdeadbeef 11 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x1bd5b7 0x6ef"
}

run_test 2.8 "decoupe 0xdeadbeef 12" && {
    $PROG 0xdeadbeef 12 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0xdeadb 0xeef"
}

run_test 2.9 "decoupe 0xdeadbeef 13" && {
    $PROG 0xdeadbeef 13 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x6f56d 0x1eef"
}

run_test 2.10 "decoupe 0 17" && {
    $PROG 0 13 > $TMP.out 2> $TMP.err || fail "erreur exec"
    verifier_sortie "0x0 0x0"
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 0xdeadbeef 12
}
