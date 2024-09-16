#!/bin/sh

PROG=${PROG:=./multiev}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "pas assez d'arguments" && {
    lancer_timeout 1 $PROG		&& fail "pas d'argument"
    verifier_usage
}

run_test 1.2 "argument 1 invalide" && {
    lancer_timeout 1 $PROG -1 2000	&& fail "arg1 == -1"
    verifier_usage
}

run_test 1.3 "argument 3 invalide" && {
    lancer_timeout 1 $PROG 2000 2000 -1	&& fail "arg3 == -1"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.1 "attentes en parallèle" && {
    # la durée totale est le maximum des durées, et pas la somme
    # autrement dit, la commande suivante doit faire 400 ms et non 1800 ms
    lancer_timeout 1 $PROG 50 100 150 200 250 300 350 400 || fail "échec"
}

run_test 2.2 "reconnaissance des événements des threads" && {
    lancer_timeout 1 $PROG 100 200 50 150			|| fail "échec"
    # vérifier que la sortie est bien "T3 T1 T4 T2"
    cat <<EOF > $TMP.att
T 3 fin usleep
T 1 fin usleep
T 4 fin usleep
T 2 fin usleep
EOF
    grep "fin usleep" $TMP.out > $TMP.res
    diff $TMP.res $TMP.att > $TMP.diff		|| fail "résultat != attendu"
}

N=1000
run_test 2.3 "concurrence maximum de $N événements" && {
    # on constitue une liste de 1000 arguments de 100 ms
    ARGS=""
    for i in $(seq $N)
    do
        ARGS="$ARGS 100"
    done
    # la commande ne doit pas durer beaucoup plus de 100 ms
    lancer_timeout 1 $PROG $ARGS 			|| fail "échec"
    nterm=$(grep "fin usleep" $TMP.out | wc -l)
    [ $nterm = $N ]		|| fail "tous les threads n'ont pas fait le usleep"
    sed -n 's/T \([0-9][0-9]*\) fin usleep/\1/p' $TMP.out | sort -n > $TMP.thr-term
    seq 1 $N | diff - $TMP.thr-term > $TMP.diff	|| fail "il manque des threads"
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 100 300
}
