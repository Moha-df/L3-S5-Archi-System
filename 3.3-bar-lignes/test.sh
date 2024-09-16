#!/bin/sh

PROG=${PROG:=./lignes}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie est correcte
# $1 = n1
# $2 = n2
verifier_sortie ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local n="$1" p="$2"

    verifier_stdout
    local nl nlatt msg
    nlatt="$p"
    nl=$(wc -l < "$TMP.out")
    [ $nl != $nlatt ] && fail "nombre de lignes ($nl) != attendu ($nlatt)"

    cat > $TMP.awk <<'EOF'
	BEGIN	{ for (i = 0 ; i < n ; i++) { l1 = l1 "#" ; l2 = l2 "-" } }
		{
		    l = (NR % 2 != 0) ? l1 : l2
		    if (l != $0)
			erreur("ligne incorrecte")
		}
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
    msg=$(awk -f $TMP.awk -v n="$n" -v p="$p" "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur : $msg"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments insuffisant" && {
    $PROG 1        > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
}

run_test 1.2 "Trop d'arguments" && {
    $PROG 1 2 3    > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.3 "arguments invalides" && {
    $PROG -1 1     > $TMP.out 2> $TMP.err	&& fail "n=-1 invalide"
    verifier_stderr
    $PROG  0 1     > $TMP.out 2> $TMP.err	&& fail "n=0 invalide"
    verifier_stderr
    $PROG 1 -1     > $TMP.out 2> $TMP.err	&& fail "p=-1 invalide"
    verifier_stderr
    $PROG 1  0     > $TMP.out 2> $TMP.err	&& fail "p=0 invalide"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "avec n=20 et p=4" && {
    lancer_timeout 2 $PROG 20 4
    verifier_sortie 20 4
}

run_test 2.2 "avec n1=1000 et n2=2000 (lent)" && {
    lancer_timeout 20 $PROG 1000 2000
    verifier_sortie 1000 2000
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 20 4
}
