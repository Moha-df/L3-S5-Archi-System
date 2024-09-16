#!/bin/sh

PROG=${PROG:=./embarq}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie de async est correcte
# $1 = n1
# $2 = n2
verifier_sortie ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local n1="$1" n2="$2"

    verifier_stdout
    local nl nlatt msg
    nlatt=$((1 + n1 + n2 + 2))
    nl=$(wc -l < "$TMP.out")
    [ $nl != $nlatt ] && fail "nombre de lignes ($nl) != attendu ($nlatt)"

    cat > $TMP.awk <<'EOF'
	/^Hotesse/  {
		    if (NR != 1) erreur("Hotesse pas en ligne 1")
		    nav = 0
		    nar = 0
		    next
		}
	/^P(arriere|avant) [0-9]+ est installe/ {
		    pos = match ($0, "avant") ? "avant" : "arriere"
		    gsub ("[^0-9]", "")
		    num = $0
		    if (pos == "avant") {
			if (nar != n2)
			    erreur("Pavant " num " assis avant que tous les Parriere ne soient assis")
			nav++
		    } else {
			nar++
		    }
		    next
		}
	/^P [0-9]+ : on peut decoller/ {
		    # pas de vérif du numéro
		    onpeut = NR
		    next
		}
	/^Avion decolle$/ {
		    decolle = NR
		    next
		}
		{ erreur("ligne " NR " invalide : " $0) }
	END	{
		    if (nar != n2) erreur("Manque " n2-nar " passagers arrière")
		    if (nav != n1) erreur("Manque " n1-nav " passagers avant")
		    if (onpeut != NR-1) erreur("Ligne \"On peut decoller\" != avant-dernière")
		    if (decolle != NR) erreur("Ligne \"Avion decolle\" != dernière")
		}
	function erreur(msg)
	{
	    if (err != 1) print msg
	    err = 1
	    exit 1
	}
EOF
    msg=$(awk -f $TMP.awk -v n1="$n1" -v n2="$n2" "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur : $msg"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nb d'arguments insuffisant" && {
    $PROG 1 2      > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
}

run_test 1.2 "trop d'arguments" && {
    $PROG 1 2 3 4  > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.3 "arguments invalides" && {
    $PROG -1 1 1   > $TMP.out 2> $TMP.err	&& fail "duree=-1 invalide"
    verifier_stderr
    $PROG 1 -1 1   > $TMP.out 2> $TMP.err	&& fail "n1=-1 invalide"
    verifier_stderr
    $PROG 1 1 -1   > $TMP.out 2> $TMP.err	&& fail "n2=-1 invalide"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "avec n1=2 et n2=3" && {
    lancer_timeout 2 $PROG 100 2 3
    verifier_sortie 2 3
}

run_test 2.2 "avec n1=500 et n2=800" && {
    lancer_timeout 2 $PROG 0 500 800
    verifier_sortie 500 800
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 0 10 20
}
