#!/bin/sh

PROG=${PROG:=./attente}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

TIMEOUT=10				# en secondes

# vérifie que la sortie du programme est correcte
# $1 = nb de threads
verifier_sortie ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local nthr="$1"

    # test effectués :
    # - tous les threads affichent "je dors"
    # - tous les threads affichent "bien dormi"
    # - "aller, debout !" est entre les "je dors" et les "bien dormi"
    # - "terminé" est après les "bien dormi"

    verifier_stdout
    local msg
    cat > $TMP.awk <<'EOF'
	    BEGIN {
		etat = "début"
	    }
	    /^thread.*je dors/ {
		num = $2
		if (num < 0 || num >= nthr)
		    erreur("Numéro de thread " num " invalide")
		if (etat != "début")
		    erreur("Thr " num " dort trop tard")
		if (thr [num])
		    erreur("Thr " num " déjà endormi")
		thr [num] = 1
		next
	    }
	    /^allez, debout/ {
		if (etat != "début")
		    erreur("allez debout affiché au muvais endroit")
		etat = "reveil"
		for (num = 0 ; num < nthr ; num++) {
		    if (! thr [num])
			erreur("Thr " num " pas endormi") ;
		}
		delete thr
		next
	    }
	    /^thread.*bien dormi/ {
		num = $2
		if (num < 0 || num >= nthr)
		    erreur("Numéro de thread " num " invalide")
		if (etat == "début")
		    erreur("Thr " num " réveillé trop tôt")
		if (etat == "terminé")
		    erreur("Thr " num " réveillé trop tard")
		if (thr [num])
		    erreur("Thr " num " déjà réveillé")
		thr [num] = 1
		next
	    }
	    /^terminé/ {
		etat = "terminé"
		for (num = 0 ; num < nthr ; num++) {
		    if (! thr [num])
			erreur("Thr " num " pas réveillé") ;
		}
		delete thr
		next
	    }
	    {
		erreur("Ligne inconnue : " $0)
	    }
	    END {
		NR = "fin"
		if (etat != "terminé")
		    erreur("Dernière ligne != \"terminé\"")
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
    msg=$(awk -f $TMP.awk -v nthr="$nthr" "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur : $msg"
}

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "pas d'argument" && {
    $PROG > $TMP.out 2> $TMP.err			&& fail "0 arg"
    verifier_usage
}

run_test 1.2 "2 arguments" && {
    $PROG 1 2 > $TMP.out 2> $TMP.err		&& fail "2 args"
    verifier_usage
}

##############################################################################
# Tests basiques

N=3
run_test 2.1 "test avec $N threads" && {
    (sleep 0.5 ; echo ) | lancer_timeout $TIMEOUT $PROG $N || fail "timeout"
    verifier_sortie $N
}

N=1000
run_test 2.2 "test avec $N threads" && {
    # on attend 1 seconde avant d'envoyer la ligne pour laisser aux
    # 1000 threads le temps de démarrer. Ce délai peut être un peu
    # peut trop court sur des machines très lentes
    (sleep 1 ; echo ) | lancer_timeout $TIMEOUT $PROG $N || fail "timeout"
    verifier_sortie $N
}

##############################################################################
# Test valgrind

N=3
run_test 3.1 "valgrind" && {
    (sleep 0.5 ; echo ) | tester_valgrind $PROG $N
}
