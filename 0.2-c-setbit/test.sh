#!/bin/sh

PROG=${PROG:=./setbit}			# chemin de l'exécutable

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
    $PROG 1 2 0 1 > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
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
    $PROG 0 0 > $TMP.out 2> $TMP.err || fail "décimal : erreur sur des arg simples"
    verifier_stdout
}

run_test 1.6 "arg val en hexadécimal" && {
# et en hexadécimal aussi
    $PROG 0x0 0 > $TMP.out 2> $TMP.err || fail "hexa : erreur sur des arg simples"
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

run_test 1.9 "arg bit < 0" && {
    $PROG 1 -1 > $TMP.out 2> $TMP.err	&& fail "bit < 0"
    verifier_stderr
}

run_test 1.10 "arg bit = 32" && {
    $PROG 1 -1 > $TMP.out 2> $TMP.err	&& fail "bit = 32"
    verifier_stderr
}

run_test 1.11 "arg 0-ou-1 = -1" && {
    $PROG 1 0 -1 > $TMP.out 2> $TMP.err	&& fail "0-ou-1 == -1"
    verifier_stderr
}

run_test 1.12 "arg 0-ou-1 = 2" && {
    $PROG 1 0 2 > $TMP.out 2> $TMP.err	&& fail "0-ou-1 == 2"
    verifier_stderr
}

##############################################################################
# Tests basiques "setbit test"

run_test 2.1 "test bit 0 à 0" && {
    $PROG 0 0 > $TMP.out 2> $TMP.err || fail "exec 0 0"
    verifier_sortie "0"
}

run_test 2.2 "test bit 0 à 1" && {
    $PROG 1 0 > $TMP.out 2> $TMP.err || fail "exec 1 0"
    verifier_sortie "1"
}

run_test 2.3 "test bit 12 à 1" && {
    $PROG 0x1000 12 > $TMP.out 2> $TMP.err || fail "exec 0x1000 12"
    verifier_sortie "1"
}

run_test 2.4 "test bit 31 à 0" && {
    $PROG 0x7fffffff 31 > $TMP.out 2> $TMP.err || fail "exec 0x7f..f 31"
    verifier_sortie "0"
}

run_test 2.5 "test bit 31 à 1" && {
    $PROG 0xffffffff 31 > $TMP.out 2> $TMP.err || fail "exec 0xff..f 31"
    verifier_sortie "1"
}

run_test 2.6 "test bit 31 à 1 (bis)" && {
    $PROG 0x80000000 31 > $TMP.out 2> $TMP.err || fail "exec 0x8...0 31"
    verifier_sortie "1"
}

##############################################################################
# Tests basiques "setbit set"

run_test 3.1 "set bit 0 à 1" && {
    $PROG 0 0 1 > $TMP.out 2> $TMP.err || fail "exec 0 0 1"
    verifier_sortie "1 0x1"
}

run_test 3.2 "set bit 0 à 0" && {
    $PROG 255 0 0 > $TMP.out 2> $TMP.err || fail "exec 255 0 1"
    verifier_sortie "254 0xfe"
}

run_test 3.3 "set bit 12 à 0" && {
    $PROG 0xdeadbeef 12 0 > $TMP.out 2> $TMP.err || fail "exec ... 12 0"
    verifier_sortie "3735924463 0xdeadaeef"
}

run_test 3.4 "set bit 12 à 1" && {
    $PROG 0xdeadbeef 12 1 > $TMP.out 2> $TMP.err || fail "exec ... 12 1"
    verifier_sortie "3735928559 0xdeadbeef"
}

run_test 3.5 "set bit 31 à 0" && {
    $PROG 0xffffffff 31 0 > $TMP.out 2> $TMP.err || fail "exec 0xffffffff 31 0"
    verifier_sortie "2147483647 0x7fffffff"
}

run_test 3.6 "set bit 31 à 1" && {
    $PROG 0 31 1 > $TMP.out 2> $TMP.err || fail "exec 0 31 1"
    verifier_sortie "2147483648 0x80000000"
}

##############################################################################
# Test valgrind

run_test 4.1 "valgrind test" && {
    tester_valgrind $PROG 0xdeadbeef 0
}

run_test 4.2 "valgrind set" && {
    tester_valgrind $PROG 0xdeadbeef 31 1
}
