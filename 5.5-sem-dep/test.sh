#!/bin/sh

PROG=${PROG:=./semdep}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

TIMEOUT=2				# en secondes

# vérifie que la sortie du programme est correcte
# $1 = fichier de sortie
verifier_sortie ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE verifier_sortie"

    # test effectués :
    # - vérifier que chaque tâche est exécutée après ses prérequis
    # - vérifier à la fin que chaque tâche a été vue une seule fois

    verifier_stdout
    local msg
    cat > $TMP.awk <<'EOF'
	    BEGIN {
		    # les prérequis des tâches
		    t [11] = ""
		    t [12] = ""
		    t [13] = ""
		    t [21] = 11 "," 12
		    t [22] = 11 "," 12 "," 13
		    t [23] = 12 "," 13
		    t [24] = 13
		    t [31] = 21 "," 13
		    t [32] = 22 "," 23 "," 24
		}
	    /^T / {
		tache = $2
		vu [tache]++
		if (tache in t) {
		    # verifier les prerequis
		    n = split (t [tache], prerequis, ",")
		    for (i = 1 ; i <= n ; i++) {
			p = prerequis [i]
			if (! vu [p])
			    erreur("prerequis " p " absent")
		    }
		} else erreur("tâche " tache "inconnue ")
	    }
	    END {
		NR = "fin"
		# verifier que toutes les taches ont été vues
		for (x in t) {
		    if (! vu[x])
			erreur("tache " x " : absente")
		    if (vu [x] > 1)
			erreur("tache " x " : vue plusieurs fois " vu[x])
		    delete vu[x]
		}
		# normalement, toutes les tâches ont été vues
		for (x in vu) {
		    erreur("tache " x " : inconnue")
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
    msg=$(awk -f $TMP.awk "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur : $msg"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "nombre d'arguments" && {
    $PROG 1 > $TMP.out 2> $TMP.err			&& fail "trop d'arg"
    verifier_usage
}

##############################################################################
# Tests basiques

run_test 2.1 "une exécution" && {
    lancer_timeout $TIMEOUT $PROG
    verifier_sortie
}

run_test 2.2 "5 exécutions" && {
    for i in 1 2 3 4 5
    do
        lancer_timeout $TIMEOUT $PROG
        verifier_sortie
    done
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind valgrind $PROG
}
