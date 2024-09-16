#!/bin/sh

PROG=${PROG:=./fin}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie du programme est correcte
# $1 = chaîne attendue (sans \n)
verifier_sortie ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local att="$1"
    local nlatt nlout

    echo "$att" > $TMP.att

    # comparer d'abord les tailles pour avoir un résultat lisible
    nlatt=$(wc -c < $TMP.att)
    nlout=$(wc -c < $TMP.out)
    [ $nlatt != $nlout ] \
	&& fail "Nb d'octets attendu ($nlatt) != sortie du programme ($nlout)"

    # le résultat de cmp est parfois difficile à interpréter
    cmp $TMP.att $TMP.out > $TMP.cmp 2> $TMP.err \
	|| fail "Résultat != attendu (cf $TMP.out, $TMP.att et $TMP.cmp)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "pas assez d'arguments" && {
    $PROG     > $TMP.out 2> $TMP.err		&& fail "pas assez d'arg"
    verifier_usage
}

run_test 1.2 "trop d'arguments" && {
    echo coucou > $TMP.in
    $PROG $TMP.in $TMP.in > $TMP.out 2> $TMP.err && fail "trop d'arg"
    verifier_usage
}

run_test 1.3 "argument n'est pas un fichier" && {
    $PROG $TMP.nonexistant > $TMP.out 2> $TMP.err && fail "fichier inexistant"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "test basique" && {
    (
        echo abcdef
        echo ghij
        echo klm
    ) > $TMP.in
    $PROG $TMP.in > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie "klm"
}

run_test 2.2 "test avec une dernière ligne vide" && {
    echo >> $TMP.in
    $PROG $TMP.in > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie ""
}

run_test 2.3 "test avec une seule ligne" && {
    echo abc > $TMP.in
    $PROG $TMP.in > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie "abc"
}

run_test 2.4 "test avec une seule ligne vide" && {
    echo > $TMP.in
    $PROG $TMP.in > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie ""
}

run_test 2.5 "test avec un fichier contenant un octet nul" && {
    generer_fichier_aleatoire $TMP.in 4	# probablement au moins 1 octet nul
    ( echo  ; echo abc) >> $TMP.in
    $PROG $TMP.in > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie "abc"
}

run_test 2.6 "test avec une ligne contenant un octet nul" && {
    ligne="kl\000m"
    (
        echo abcdef
        echo ghij
        echo "$ligne"
    ) > $TMP.in
    $PROG $TMP.in > $TMP.out 2> $TMP.err	|| fail "erreur d'exécution"
    verifier_sortie "$ligne"
}

##############################################################################
# Tests de performance

run_test 3.1 "test de performance" && {
    # utiliser un tout petit fichier
    echo abc > $TMP.in
    $TIME -p $PROG $TMP.in > $TMP.out 2> $TMP.time1
    t1=$(duree $TMP.time1)
    verifier_sortie "abc"

    # prendre un très gros fichier (256 Mo) et créer une ligne à la fin
    generer_fichier_aleatoire $TMP.in 256
    ( echo  ; echo abc) >> $TMP.in
    $TIME -p $PROG $TMP.in > $TMP.out 2> $TMP.time2
    t2=$(duree $TMP.time2)
    # la différence de temps entre les deux doit être négligeable
    verifier_sortie "abc"

    # temps d'un petit fichier ne devrait pas être < 90 % du
    # temps d'un gros fichier
    # (les deux devraient être quasiment identiques)
    [ $t1 -lt $((t2 * 90 / 100)) ] \
    	&& fail "Performance petit fichier ($t1 ms) != gros fichier ($t2 ms)"
}

##############################################################################
# Test valgrind

run_test 4.1 "valgrind" && {
    echo abc > $TMP.in
    tester_valgrind $PROG $TMP.in
}
