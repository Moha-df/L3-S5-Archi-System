#!/bin/sh

PROG1=${PROG1:=./ctypes-unique}		# chemin de l'exécutable
PROG2=${PROG2:=./ctypes-global}		# chemin de l'exécutable
PROG3=${PROG3:=./ctypes-local}		# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# les paramètres sont liés : plus la taille est grande, plus le temps est grand
# (il faut des grands fichiers pour avoir des mesures de temps significatives)
TAILLE=16				# fichier de test : $TAILLE mégaoctets
TIMEOUT=60				# timeout en secondes

# Vérifier le test des arguments
# $1 = le programme à tester
tester_arg ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE tester_arg"
    local prog="$1"

    "$prog"      > $TMP.out 2> $TMP.err	&& fail "pas d'arg"
    verifier_usage
    "$prog" $TMP.nonexistant > $TMP.out 2> $TMP.err && fail "arg pas un fichier"
    verifier_stderr
}

# Crée des fichiers de test et détermine les valeurs atten
# $1 = taille (en Mo) des fichiers à créer
# retour : 2 variables "total" et "alnum"
creer_4_fichiers ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE creer_4_fichiers"
    local taille="$1"

    for i in 1 2 3 4
    do
        generer_fichier_aleatoire $TMP.$i $taille
    done
    # extraction des valeurs de référence
    total=$(cat $TMP.[1-4] | wc -c)
    alnum=$(cat $TMP.[1-4] | tr -d -c A-Za-z0-9 | wc -c)
}


# Vérifier les valeurs affichées par ctypes-*
# $1 = timeout en secondes
# $2 = le programme à lancer (sur $TMP.[1-4]
# $3 = nb (déjà calculé) d'alnum
# $4 = taille totale du fichier
# Variables : TMP, TIME
# sortie : durée en ms dans TMP.time
lancer_verifier ()
{
    [ $# != 4 ] && fail "ERREUR SYNTAXE lancer_verifier"
    local timeout="$1" prog="$2" alnum="$3" total="$4"
    local duree i v somme

    lancer_timeout $timeout $TIME -p $prog $TMP.[1-4] || fail "échec"
    duree $TMP.err > $TMP.time

    [ $(wc -l < "$TMP.out") != 1 ] && fail "sortie != une seule ligne"

    v=$(cut -d ' ' -f 1 < "$TMP.out")
    [ $v != $alnum ] && fail "$v = mauvais nb d'alnum (devrait être $alnum)"

    somme=$v
    for i in 2 3 4
    do
	v=$(cut -d ' ' -f $i < "$TMP.out")
	somme=$((somme + v))
    done
    [ $somme != $total ] && fail "somme des nb = $somme (devrait être $total)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments ctypes-unique" && {
    tester_arg $PROG1
}

run_test 1.2 "nb d'arguments ctypes-global" && {
    tester_arg $PROG2
}

run_test 1.3 "nb d'arguments ctypes-local" && {
    tester_arg $PROG3
}

##############################################################################
# Tests basiques de fonctionnement

run_test 2.1 "resultat ctypes-unique" && {
    creer_4_fichiers 1
    lancer_verifier $TIMEOUT $PROG1 $alnum $total
}

run_test 2.2 "resultat ctypes-global" && {
    creer_4_fichiers 1
    lancer_verifier $TIMEOUT $PROG2 $alnum $total
}

run_test 2.3 "resultat ctypes-local" && {
    creer_4_fichiers 1
    lancer_verifier $TIMEOUT $PROG3 $alnum $total
}

##############################################################################
# Tests de cohérence des durées d'exécution

run_test 3.1 "cohérence des temps d'exécution (lent)" 80 && {
    creer_4_fichiers $TAILLE

    lancer_verifier $TIMEOUT $PROG1 $alnum $total
    t1=$(cat $TMP.time)
    lancer_verifier $TIMEOUT $PROG2 $alnum $total
    t2=$(cat $TMP.time)
    lancer_verifier $TIMEOUT $PROG3 $alnum $total
    t3=$(cat $TMP.time)

    # tolérances admises : t2 devrait être dans [70 % t1, 150 % t1[
    [ $t2 -ge $(($t1 * 150 / 100)) ] && \
        fail "ctypes-unique ($t1) devrait être plus lent que ctypes-global ($t2)"
    [ $t2 -le $((t1 * 70 / 100)) ] && \
        fail "ctypes-global ($t1) ne devrait pas être beaucoup plus lent que ctypes-global ($t2)"
    # tolérances admises : t3 devrait être < 20 % de t1
    [ $t3 -gt $((t1 * 20 / 100)) ] && \
        fail "ctypes-local ($t3) devrait être beaucoup plus rapide que les autres ($t1)"
}

##############################################################################
# Test valgrind

preparer4 ()
{
    # utiliser des fichiers plus petits car valgrind ralentit
    generer_fichier_aleatoire $TMP.1 4
    generer_fichier_aleatoire $TMP.2 4
}

run_test 4.1 "valgrind ctypes-unique (lent)" 10 && {
    preparer4
    tester_valgrind $PROG1 $TMP.1 $TMP.2
}

run_test 4.2 "valgrind ctypes-global (lent)" 10 && {
    preparer4
    tester_valgrind $PROG2 $TMP.1 $TMP.2
}

run_test 4.3 "valgrind ctypes-local (lent)" 10 && {
    preparer4
    tester_valgrind $PROG3 $TMP.1 $TMP.2
}
