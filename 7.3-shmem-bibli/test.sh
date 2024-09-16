#!/bin/sh

# Chemins des exécutables
PROG_RANGER=${PROG_RANGER:=./ranger}
PROG_SORTIR=${PROG_SORTIR:=./sortir}

# lire les variables et fonctions communes
. ../test-inc.sh

# tester que le programme fourni (avec ses arguments) donne bien une erreur
# $1 = message d'erreur
# $2 et suivants = le programme et ses arguments (sans espaces) éventuels
tester_erreur ()
{
    [ $# -le 1 ] && fail "ERREUR SYNTAXE tester_erreur"

    local msg="$1"
    shift

    lancer_timeout 1 $*		&& fail "$1: pas d'erreur détectée ($msg)"
    verifier_stderr
}

# tester des arguments invalides
# $1 = message d'erreur
# $2 et suivants = le programme et ses arguments (sans espaces) éventuels
tester_usage ()
{
    [ $# -le 1 ] && fail "ERREUR SYNTAXE tester_usage"

    local msg="$1"
    shift

    tester_erreur "$msg" $*
    verifier_usage
}

##############################################################################
# Tests des arguments

run_test 1.1 "arguments de 'ranger'" && {
    tester_usage "pas assez d'arguments" $PROG_RANGER $TMP.bib A
    tester_usage "trop d'arguments"      $PROG_RANGER $TMP.bib A 1 10
}

run_test 1.2 "validité du nb de pages" && {
    tester_erreur "nb de pages = 0" $PROG_RANGER $TMP.bib A 0
    tester_erreur "nb de pages < 0" $PROG_RANGER $TMP.bib A -1
}

run_test 1.3 "longueur du titre" && {
    $PROG_RANGER $TMP.bib abcdefghij 123 || fail "erreur exécution titre 10 car"
    tester_erreur "titre trop long" $PROG_RANGER $TMP.bib abcdefghijX 123
}

run_test 1.4 "validité du fichier pour 'ranger'" && {
    touch $TMP.bib
    chmod 0 $TMP.bib
    tester_erreur "répertoire" $PROG_RANGER $TMP.bib A 5
}

run_test 1.5 "arguments de sortir" && {
    tester_usage "pas assez d'arguments" $PROG_SORTIR $TMP.bib
    tester_usage "trop d'arguments"      $PROG_SORTIR $TMP.bib A 1
}

run_test 1.6 "validité du fichier pour 'sortir'" && {
    touch $TMP.bib
    chmod 0 $TMP.bib
    tester_erreur "répertoire" $PROG_SORTIR $TMP.bib A
}

##############################################################################
# Écriture du fichier

run_test 2.1 "ranger un livre" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger'"
}

run_test 2.2 "ranger deux livres" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' A"
    sz1=$(wc -c < $TMP.bib)
    $PROG_RANGER $TMP.bib B 2 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' B"
    sz2=$(wc -c < $TMP.bib)
    [ $sz1 -lt $sz2 ] || fail "Le fichier devrait grandir au 2e livre ($sz1 -> $sz2"
}

run_test 2.3 "ranger trois livres" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' A"
    $PROG_RANGER $TMP.bib B 2 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' B"
    sz1=$(wc -c < $TMP.bib)
    $PROG_RANGER $TMP.bib C 3 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' C"
    sz2=$(wc -c < $TMP.bib)
    [ $sz1 -lt $sz2 ] || fail "Le fichier devrait grandir au 3e livre ($sz1 -> $sz2"
}

run_test 2.4 "vérification du magic par 'ranger'" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' A"
    # remplacer le magic sans modifier le reste du fichier
    echo ABC | dd of=$TMP.bib conv=notrunc 2> /dev/null
    cp $TMP.bib $TMP.sav
    tester_erreur "pas de vérification du magic" $PROG_RANGER $TMP.bib B 2
    # le fichier ne devrait pas avoir changé
    cmp $TMP.bib $TMP.sav > $TMP.out || fail "Fichier modifié après vérif du magic"
}

##############################################################################
# Lecture du fichier

run_test 3.1 "vérification du magic par 'sortir'" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' A"
    # remplacer le magic sans modifier le reste du fichier
    echo ABC | dd of=$TMP.bib conv=notrunc 2> /dev/null
    tester_erreur "'ranger' ne vérifie pas le magic" $PROG_RANGER $TMP.bib B 2
    tester_erreur "'sortir' ne vérifie pas le magic" $PROG_SORTIR $TMP.bib A
}

run_test 3.2 "sortir un livre" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' A"
    $PROG_RANGER $TMP.bib B 2 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' B"
    $PROG_RANGER $TMP.bib C 3 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' C"
    sz1=$(wc -c < $TMP.bib)
    $PROG_SORTIR $TMP.bib B   > $TMP.out 2> $TMP.err || fail "Echec 'sortir B'"
    # vérifier le nombre de pages en sortie
    n=$(cat $TMP.out)
    [ "x$n" != x2 ] && fail "sortir B ne retourne pas le bon nb de pages ($n)"
    # vérifier que la taille du fichier n'a pas été modifiée
    sz2=$(wc -c < $TMP.bib)
    [ $sz1 != $sz2 ] && fail "sortir ne devrait pas modifier la taille du fichier"
    # on doit réutiliser l'emplacement libéré
    $PROG_RANGER $TMP.bib D 4 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' D"
    sz3=$(wc -c < $TMP.bib)
    [ $sz1 != $sz2 ] && fail "ranger devrait utiliser l'emplacement libre"
}

run_test 3.3 "livre non trouvé" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' A"
    $PROG_RANGER $TMP.bib B 2 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' B"
    $PROG_RANGER $TMP.bib C 3 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' C"
    tester_erreur "D n'existe pas" $PROG_SORTIR $TMP.bib D
}

run_test 3.4 "livre sorti ne peut pas être trouvé" && {
    $PROG_RANGER $TMP.bib A 1 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' A"
    $PROG_RANGER $TMP.bib B 2 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' B"
    $PROG_RANGER $TMP.bib C 3 > $TMP.out 2> $TMP.err || fail "Echec 'ranger' C"
    $PROG_SORTIR $TMP.bib B   > $TMP.out 2> $TMP.err || fail "Echec 'sortir' B"
    tester_erreur "B n'existe plus" $PROG_SORTIR $TMP.bib B
}

##############################################################################
# Test valgrind

run_test 4.1 "valgrind" && {
    tester_valgrind $PROG_RANGER $TMP.bib A 1
    tester_valgrind $PROG_RANGER $TMP.bib B 2
    tester_valgrind $PROG_SORTIR $TMP.bib B
}
