#!/bin/sh

PROG=${PROG:=./fichiers}		# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifier la sortie
# $1 = résultat attendu (fichier)
# $2 = résultat attendu (nb de lettres)
# $3 = résultat attendu (proportion)
verifier_sortie ()
{
    [ $# != 3 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local fichier="$1" nlet="$2" prop="$3"
    local res diff

    verifier_stdout
    res=$(cut -d' ' -f1 "$TMP.out")
    [ "x$res" != x"$fichier" ]	&& fail "résultat ($res) != attendu ($fichier)"

    res=$(cut -d' ' -f2 "$TMP.out")
    [ "x$res" != x"$nlet" ]	&& fail "résultat ($nlet) != attendu ($nlet)"

    res=$(cut -d' ' -f3 "$TMP.out")
    # calculer la différence jusqu'à la cinquième décimale
    diff=$(echo "scale=0;x=100000*($res-$prop);if(x<0) -x;if(x>=0) x" \
    		| bc | sed 's/\..*//')
    [ "$diff" -gt 1 ]		&& fail "résultat ($res) != attendu ($prop)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments peut être nul" && {
    $PROG       > $TMP.out 2> $TMP.err	|| fail "il faut accepter 0 arg"
    est_vide $TMP.out			|| fail "stdout devrait être vide"
    est_vide $TMP.err			|| fail "stderr devrait être vide"
}

run_test 1.2 "argument invalide" && {
    lancer_timeout 1 $PROG $TMP.nonexistant && fail "pas d'erreur détectée"
    verifier_stderr
}

##############################################################################
# Tests basiques

tab=$(printf "\t")

run_test 2.1 "test de bon fonctionnement sur un fichier construit" && {
# 12 lettres, 6 espaces/tab sur 12+6+10+2=30 octets, soit 0,2"
    printf "ABC abc DEF def${tab}12345 67890 !+" > $TMP.in
    lancer_timeout 1 $PROG $TMP.in	|| fail "erreur sur lecture de $TMP.in"
    verifier_sortie $TMP.in 12 0.2
}

run_test 2.2 "test de bon fonctionnement sur stdio.h" && {
    cible=/usr/include/stdio.h
    taille=$(wc -c < $cible)
    nlet=$(tr -c -d A-Za-z < $cible | wc -c)
    nblk=$(tr -c -d " ${tab}" < $cible | wc -c)
    prop=$(echo "scale=5;$nblk/$taille" | bc)
    lancer_timeout 1 $PROG $cible	|| fail "erreur sur lecture de $cible"
    verifier_sortie $cible $nlet $prop
}

##############################################################################
# Tests avec plein de threads

run_test 3.1 "test avec plein de threads" && {
    nf=$(ls /usr/include/*.h | wc -l)	# nombre de fichiers
    # timeout de 10 s => ça devrait être suffisamment rapide
    lancer_timeout 10 $PROG /usr/include/*.h || fail "erreur sur /usr/include/*.h"
    verifier_stdout
    nl=$(wc -l < $TMP.out)	# nombre de lignes dans la sortie
    [ $nl != $nf ]		&& fail "nb de lignes ($nl) != attendu ($nf)"
}

##############################################################################
# Test valgrind

run_test 4.1 "valgrind" && {
    tester_valgrind $PROG /usr/include/*.h
}
