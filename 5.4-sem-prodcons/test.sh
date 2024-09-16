#!/bin/sh

PROG=${PROG:=./tampon}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

TIMEOUT=5				# en secondes

# vérifie que la sortie du programme est correcte
# $1 = D
# $2 = P
# $3 = C
# $4 = B
verifier_sortie ()
{
    [ $# != 4 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local d="$1" p="$2" c="$3" b="$4"

    # test effectués :
    # - chaque donnée produite est consommée par un consommateur
    #	(ne pas compter sur un ordre prod < cons, car il y a indéterminisme)
    # - les numéros de données sont compris entre 1 et d*p
    # - chaque producteur a produit au moins une donnée
    # - chaque consommateur a consommé au moins une donnée
    # Ces tests fonctionnent avec ou sans protocole de terminaison
    # (i.e. lorsque le programme est stoppé par le timeout)
    # sous réserve qu'il y ait des "fflush(stdout)" après chaque affichage

    verifier_stdout
    local msg
    cat > $TMP.awk <<'EOF'
	    /^[PC] / {
		PC = $1 ; i = $2 ; n = $3 ; v = $4
		donnee = n "/" v
		if (v != -1 && (n < 1 || n > d*p))
		    erreur("donnée " n " pas dans [1," d*p"]")
		if (PC == "P") {
		    producteurs [i] = 1
		    produit [donnee]++
		    if (donnees [n])
			erreur("donnée déjà produite") ;
		    donnees [n] = 1
		} else {
		    consommateurs [i] = 1
		    consomme [donnee]++
		}
	    }
	    END {
		NR = "fin"
		for (donn in produit)
		{
		    if (produit [donn] > 1)
			erreur("donnée " donn " produite plus de 1 fois")
		    if (! (donn in consomme))
			erreur("donnée " donn " non consommée")
		    if (consomme [donn] > 1)
			erreur("donnée " donn " consommée plus de 1 fois")
		    delete produit[donn]
		    delete consomme[donn]
		}
		for (donn in consomme)
		    erreur("donnée " donn " consommée et non produite")

		for (i = 1 ; i <= d * p ; i++)
		    if (! donnees [i])
			erreur("donnée " i " pas produite")
		for (i = 0 ; i < p ; i++)
		    if (! producteurs [i])
			erreur("producteur " i " : rien produit")
		if (d * p * 10 > c)
		{
		    for (i = 0 ; i < c ; i++)
			if (! consommateurs [i])
			    erreur("consommateur " i " : rien consommé")
		}
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
    msg=$(awk -f $TMP.awk -v d="$d" -v p="$p" -v c="$c" -v b="$b" "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur : $msg"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nombre d'arguments" && {
    $PROG 1 1 1       > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage

    $PROG 1 1 1 1 1   > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.2 "arguments invalides" && {
    $PROG 0 1 1 1     > $TMP.out 2> $TMP.err	&& fail "arg 1 = 0"
    verifier_usage
    $PROG 1 0 1 1     > $TMP.out 2> $TMP.err	&& fail "arg 2 = 0"
    verifier_usage
    $PROG 1 1 0 1     > $TMP.out 2> $TMP.err	&& fail "arg 3 = 0"
    verifier_usage
    $PROG 1 1 1 0     > $TMP.out 2> $TMP.err	&& fail "arg 4 = 0"
    verifier_usage

    $PROG -1 1 1 1    > $TMP.out 2> $TMP.err	&& fail "arg 1 = -1"
    verifier_usage
    $PROG 1 -1 1 1    > $TMP.out 2> $TMP.err	&& fail "arg 2 = -1"
    verifier_usage
    $PROG 1 1 -1 1    > $TMP.out 2> $TMP.err	&& fail "arg 3 = -1"
    verifier_usage
    $PROG 1 1 1 -1    > $TMP.out 2> $TMP.err	&& fail "arg 4 = -1"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.1 "tampon 5 1 1 10" && {
    lancer_timeout $TIMEOUT $PROG 5 1 1 10 || fail "Erreur à l'exécution"
    verifier_sortie 5 1 1 10
}

# contention sur les producteurs, pas trop sur les consommateurs
run_test 2.2 "tampon 100 100 100 2" && {
    lancer_timeout $TIMEOUT $PROG 100 100 100 2 || fail "Erreur à l'exécution"
    verifier_sortie 100 100 100 2
}

# contention sur les producteurs et sur les consommateurs
run_test 2.3 "tampon 100 100 2 100" && {
    lancer_timeout $TIMEOUT $PROG 100 100 2 100 || fail "Erreur à l'exécution"
    verifier_sortie 100 100 2 100
}

##############################################################################
# Tests de terminaison

run_test 3.1 "terminaison tampon 100 10 100 3" && {
    lancer_timeout $TIMEOUT $PROG 100 10 100 3
    verifier_sortie 100 10 100 3
}

##############################################################################
# Test valgrind

run_test 4.1 "valgrind tampon 5 1 1 10" && {
    tester_valgrind $PROG 5 1 1 10
}
