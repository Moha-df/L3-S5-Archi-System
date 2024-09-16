#!/bin/sh

PROG=${PROG:=./serpar}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie de serpar est correcte
verifier_sortie ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE verifier_sortie"

    verifier_stdout
    local nl msg
    nl=$(wc -l < "$TMP.out")
    [ $nl != 10 ] && fail "nombre de lignes ($nl) != attendu (10)"
    cat > $TMP.awk <<'EOF'
	/^[0-9]+$/ { l [$0] = NR ; next }
		{ erreur("ligne invalide : " $0) }
	 END	{
		    NR = "fin"
		    if (l [1] != 1) erreur("tache 1 pas en ligne 1")
		    if (l [31] < l [21]) erreur("tache 31 avant 21")
		    if (l [32] < l [21]) erreur("tache 32 avant 21")
		    if (l [33] < l [21]) erreur("tache 33 avant 21")
		    if (l [41] < l [31]) erreur("tache 41 avant 31")
		    if (l [41] < l [32]) erreur("tache 41 avant 32")
		    if (l [41] < l [33]) erreur("tache 41 avant 33")
		    if (l [34] < l [22]) erreur("tache 34 avant 22")
		    if (l [42] < l [34]) erreur("tache 42 avant 34")
		    if (l [5] < l [41])  erreur("tache 5 avant 41")
		    if (l [5] < l [42])  erreur("tache 5 avant 42")
		}
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
    msg=$(awk -f $TMP.awk "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur : $msg"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments" && {
    $PROG 1 > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.1 "fonctionnement" && {
    lancer_timeout 2 $PROG
    verifier_sortie
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG
}
