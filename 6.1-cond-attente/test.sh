#!/bin/sh

PROG=${PROG:=./attente}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie du programme est correcte pour d1 = d2 = 0
verifier_sortie ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE verifier_sortie"

    # Il n'y a que 5 messages possibles
    #	A- T1 fin usleep
    #	B- T1 attente terminaison T2
    #	C- T1 terminé
    #	D- T2 fin usleep
    #	E- T2 terminé
    # Graphe de dépendances de ces messages
    #	A avant B avant C
    #   D avant E
    #   E avant C

    verifier_stdout
    local msg
    cat > $TMP.awk <<'EOF'
	    BEGIN {
		# les prérequis de chaque ligne
		t ["T1 fin usleep"] = ""
		t ["T1 attente terminaison T2"] = "T1 fin usleep"
		t ["T1 terminé"] = "T1 attente terminaison T2,T2 terminé"
		t ["T2 fin usleep"] = ""
		t ["T2 terminé"] = "T2 fin usleep"
		t ["fin"] = "T1 terminé"
	    }
	    /^T1 fin usleep/			{ voir($0) ; next }
	    /^T1 attente terminaison T2/	{ voir($0) ; next }
	    /^T1 terminé/			{ voir($0) ; next }
	    /^T2 fin usleep/			{ voir($0) ; next }
	    /^T2 terminé/			{ voir($0) ; next }
	    {
		erreur("ligne non reconnue : $0")
	    }
	    END {
		NR = "fin"
		voir("fin")
	    }
	    function voir(ligne)
	    {
		if (vu [ligne])
		    erreur("ligne " ligne " déjà vue")
		# vérifier les prérequis
		n = split (t [ligne], prerequis, ",")
		for (i = 1 ; i <= n ; i++) {
		    p = prerequis [i]
		    if (! vu [p])
			erreur("ligne \"" ligne "\" : prérequis \"" p "\" absent") ;
		}
		vu [ligne] = 1
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

run_test 1.1 "pas assez d'arguments" && {
    $PROG 1 > $TMP.out 2> $TMP.err		&& fail "1 arg"
    verifier_usage
}

run_test 1.2 "trop d'arguments" && {
    $PROG 1 2 3 > $TMP.out 2> $TMP.err		&& fail "3 args"
    verifier_usage
}

run_test 1.3 "arg 1 invalide" && {
    $PROG -1 1 > $TMP.out 2> $TMP.err		&& fail "arg1 == -1"
    verifier_usage
}

run_test 1.4 "arg 2 invalide" && {
    $PROG 1 -1 > $TMP.out 2> $TMP.err		&& fail "arg2 == -1"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.1 "test d1 > d2" && {
    lancer_timeout 1 $PROG 300 100		|| fail "exit != 0"
    # avec ces paramètres, il ne peut y avoir qu'une seule sortie possible
    cat <<EOF > $TMP.ref
T2 fin usleep
T1 fin usleep
T1 attente terminaison T2
T2 terminé
T1 terminé
EOF
    diff $TMP.ref $TMP.out > $TMP.diff		|| fail "résultat != attendu"
}

run_test 2.2 "test d1 < d2" && {
    nettoyer
    lancer_timeout 1 $PROG 100 300			|| fail "exit != 0"
    # avec ces paramètres, il ne peut y avoir qu'une seule sortie possible
    cat <<EOF > $TMP.ref
T1 fin usleep
T1 attente terminaison T2
T2 fin usleep
T2 terminé
T1 terminé
EOF
    diff $TMP.ref $TMP.out > $TMP.diff		|| fail "résultat != attendu"
}

N=500
run_test 2.3 "test d1 = d2 = 0 ($N fois)" && {
    for i in $(seq $N)
    do
        lancer_timeout 1 $PROG 0 0			|| fail "exit != 0"
        verifier_sortie
    done
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 100 300
}
