#!/bin/sh

PROG=${PROG:=./partez}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie de async est correcte
# $2 = n1
# $3 = n2
verifier_sortie ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local n="$1"

    verifier_stdout

    local nl nlatt nelu
    nlatt=$((n + 1))
    nl=$(wc -l < "$TMP.out")
    [ $nl != $nlatt ] && fail "nombre de lignes ($nl) != attendu ($nlatt)"

    # Vérifier que "Saisie au clavier" est bien affiché en premier
    # (peu de risque de voir échouer ce test
    head -1 "$TMP.out" | grep -q "^Saisie au clavier :" \
	    || fail "Pas de ligne 'Saisie au clavier'"

    # Vérifier que la dernière ligne est bien "Terminé"
    tail -1 "$TMP.out" | grep -q "^Terminé$" \
	    || fail "Dernière ligne != 'Terminé'"

    # Vérifier que chaque thread affiche son numéro et qu'ils sont tous
    # différents
    sed \
	    -e 's/Saisie au clavier : //' \
	    -e 's/^Thread //' \
	    -e 's/, je suis élu//' \
	    -e '/^Terminé/d' \
	    "$TMP.out" \
	| sort -n | uniq -c > "$TMP.out.num"
    [ $(wc -l < "$TMP.out.num") != $n ] && fail "Numéros de threads en double"

    # Vérifier qu'il y a bien un élu
    nelu=$(grep ", je suis élu" "$TMP.out" | wc -l)
    [ $nelu != 1 ] && fail "Il devrait y avoir exactement 1 élu (et pas $n)"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments" && {
    $PROG          > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
    $PROG 1 2      > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.2 "argument invalide" && {
    $PROG -1       > $TMP.out 2> $TMP.err	&& fail "n=-1 invalide"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "avec n=3" && {
    echo | lancer_timeout 1 $PROG 3
    verifier_sortie 3
}

run_test 2.2 "avec n=1000" && {
    echo | lancer_timeout 1 $PROG 1000
    verifier_sortie 1000
}

run_test 2.3 "pas prêt tout de suite" && {
    # attendre 500 ms avant d'envoyer le top départ
    (sleep 0.5 ; echo) | $TIME -p $PROG 10 > $TMP.out 2> $TMP.time
    t=$(duree $TMP.time)
    verifier_duree $t 500 700
    # créer un TMP.err vide pour le test de verifier_sortie
    > $TMP.err
    verifier_sortie 10
}

##############################################################################
# Test de l'élu

run_test 3.1 "test de non déterminisme (lent)" && {
    NRUN=100
    for i in $(seq $NRUN)
    do
        echo | $PROG 1000 | grep ", je suis élu"
    done > $TMP.out
    # Normalement, il devrait y avoir $NRUN fois un élu
    nelus=$(wc -l < $TMP.out)
    [ $nelus != $NRUN ] \
    	&& fail "Il devrait y avoir $NRUN lignes dans $TMP.out et pas $nelus"
    # Normalement, sur les $NRUN essais, tous ne devraient pas donner le
    # même numéro d'élu
    nthelus=$(sort -n $TMP.out | uniq -c | wc -l)
    [ $nthelus = 1 ] && fail "C'est toujours le même thread qui est élu"
}

##############################################################################
# Test valgrind

run_test 4.1 "valgrind" && {
    echo | tester_valgrind $PROG 10
}
