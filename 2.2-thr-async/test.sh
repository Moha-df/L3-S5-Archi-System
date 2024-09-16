#!/bin/sh

PROG=${PROG:=./async}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie de async est correcte
# $1 = fichier de sortie
# $2 = nb de lignes attendu ou -1
verifier_sortie ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local out="$1" nlatt="$2"

    verifier_stdout
    local nl msg
    nl=$(wc -l < "$TMP.out")
    [ $nl != $nlatt ] && fail "nombre de lignes = $nl != $nlatt"
    cat > $TMP.awk <<'EOF'
	BEGIN	{ termine = 0 }
	/^[0-9]+ *%$/ {
		    if (termine) erreur("% apres 'termine'")
		    sub (" *%", "")
		    if (prevpcent > $0) erreur("% invalide")
		    next
		}
	/^termine$/ { termine = 1 ; next }
		{ erreur("ligne invalide : " $0) }
	END	{
		    NR = "fin"
		    if (! termine) erreur("Manque ligne 'termine'")
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
    $PROG       > $TMP.out 2> $TMP.err	&& fail "pas assez d'arg"
    verifier_usage
    nettoyer
    $PROG 1 1   > $TMP.out 2> $TMP.err	&& fail "trop d'arg"
    verifier_usage
}

run_test 1.2 "arguments invalides" && {
    $PROG -1      > $TMP.out 2> $TMP.err	&& fail "duree=-1 invalide"
    verifier_stderr
    $PROG 0       > $TMP.out 2> $TMP.err	&& fail "n=0 invalide"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "terminaison" && {
    # on lance avec la progression la plus rapide (=> test rapide)
    # (1 % à chaque ms, c'est donc fini au bout de 100 ms)
    lancer_timeout 2 $PROG 1
    verifier_sortie $TMP.out 2
}

run_test 2.2 "progression significative" && {
    # un incrément toutes les 40 ms => 25 incréments par seconde
    # soit 25 % de plus à chaque seconde. Dans la pratique, c'est
    # un peu moins car il y a un peu d'overhead et usleep n'est
    # pas très précis sur tous les systèmes
    # => il faut 100 / 25 = 4,x secondes (avec x faible)
    # on utilise une marge car certaines machines ont un "usleep" peu précis
    lancer_timeout 5.5 $PROG 40
    verifier_sortie $TMP.out 6
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 1
}
