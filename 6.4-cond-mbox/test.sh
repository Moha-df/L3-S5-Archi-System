#!/bin/sh

PROG=${PROG:=./mbox}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie est correcte
# $1 = p
# $2 = ne
# $3 = nr
verifier_sortie ()
{
    [ $# != 3 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local p="$1" ne="$2" nr="$3"

    verifier_stdout

    local nl nlatt msg
    nlatt=$((1 + nr))
    nl=$(wc -l < "$TMP.out")
    [ $nl != $nlatt ] && fail "nombre de lignes ($nl) != attendu ($nlatt)"

    cat > $TMP.awk <<'EOF'
	BEGIN	{ n = 0 }
	/^T[0-9]+ : nb recus = [0-9]+$/
		{ sub (".*recus = ", "") ; n += $0 ; next }
	/^total = [0-9]+, attendu = [0-9]+/
		{
		    sub ("total = ", "") ; sub (", attendu.*", "")
		    if ($0 != n)
			erreur("nb msg reçus (" $0 ") != somme des affichés (" n ")")
		    if ($0 != ne * p)
			erreur("nb msg reçus (" $0 ") != attendu")
		}
		{ erreur("ligne invalide : " $0) }
	END	{ NR = "fin" }
	function erreur(msg)
	{
	    if (err != 1) {
		if (NR != "fin")
		    print "ligne " NR ": " msg
		else print msg
	    }
	    err = 1
	    exit 1
	}
EOF
    msg=$(awk -f $TMP.awk -v p="$p" -v ne="$ne" -v nr="$nr" "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur pour p=$p ne=$ne nr=$nr : $msg"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments insuffisant" && {
    $PROG 1 2 3     > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
}

run_test 1.2 "trop d'arguments" && {
    $PROG 1 2 3 4 5 > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.3 "arguments invalides" && {
    $PROG -1 1 1 1  > $TMP.out 2> $TMP.err	&& fail "t=-1 invalide"
    verifier_stderr
    $PROG 1 -1 1 1  > $TMP.out 2> $TMP.err	&& fail "p=-1 invalide"
    verifier_stderr
    $PROG 1 1 -1 1  > $TMP.out 2> $TMP.err	&& fail "ne=-1 invalide"
    verifier_stderr
    $PROG 1 1  0 1  > $TMP.out 2> $TMP.err	&& fail "ne=0 invalide"
    verifier_stderr
    $PROG 1 1 1 -1  > $TMP.out 2> $TMP.err	&& fail "nr=-1 invalide"
    verifier_stderr
    $PROG 1 1 1  0  > $TMP.out 2> $TMP.err	&& fail "nr=0 invalide"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "avec t=10, ne=1, nr=1" && {
    lancer_timeout 2 $PROG 10 100 1 1
    est_vide $TMP.err			|| fail "sortie sur stderr"
    verifier_sortie 100 1 1
}

run_test 2.2 "avec t=10, ne=5, nr=7" && {
    lancer_timeout 2 $PROG 10 100 5 7
    est_vide $TMP.err			|| fail "sortie sur stderr"
    verifier_sortie 100 5 7
}

run_test 2.3 "avec t=variable, ne=variable, nr=2 (lent)" && {
    for t in 0 1 3
    do
        for ne in 1 3 10 50
        do
	    # echo $t $ne			# debug
	    lancer_timeout 10 $PROG $t 100 $ne 2
	    est_vide $TMP.err		|| fail "sortie sur stderr"
	    verifier_sortie 100 $ne 2
        done
    done
}

run_test 2.4 "avec t=variable, ne=1, nr=variable (lent)" && {
    for t in 0 1 3 5
    do
        for nr in 1 10 50
        do
	    # echo $t $nr			# debug
	    lancer_timeout 10 $PROG $t 100 1 $nr
	    est_vide $TMP.err		|| fail "sortie sur stderr"
	    verifier_sortie 100 1 $nr
        done
    done
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 0 1000 20 10
}
