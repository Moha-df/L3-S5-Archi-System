#!/bin/sh

PROG=${PROG:=./ccalc}			# chemin de l'exécutable

# lire les variables et fonctions communes
. ../test-inc.sh

# vérifie que la sortie est correcte
# $1 = m
# $2 = n
# $3 = p
# $4 = tmax
verifier_sortie ()
{
    [ $# != 4 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local m="$1" n="$2" p="$3" tmax="$4"

    verifier_stdout

    local msg
    cat > $TMP.awk <<'EOF'
	/^user [0-9]+ job [0-9]+ machines [0-9]+ duration [0-9]+ ms$/ {
			ju = $2 ; jj = $4 ; jm = $6 ; jd = $8
			if (jm < 1 || jm > max)
			    erreur("nb de machines " jm " invalide")
			m -= jm
			if (m < 0)
			    erreur("plus assez de machines")
			if (ju < 0 || ju >= n)
			    erreur("user " ju " invalide")
			if (jj < 1 || jj > p)
			    erreur("job " jj " invalide")
			if (jd < 0 || jd > tmax)
			    erreur("durée " jd " invalide")
			vu [ju,jj]++
			if (vu [ju,jj] > 1)
			    erreur("user " ju "/job " jj " déjà vu")
			job [ju,jj] = jm
		    }
	/^fin user [0-9]+ job [0-9]+$/ {
			ju = $3 ; jj = $5
			if (job [ju,jj] > 0) {
			    m += job [ju,jj]
			    if (m > max)
				erreur("nb machines = " m " > " max)
			    delete job[ju,jj]
			} else if (vu [ju,jj] > 0) {
			    erreur("user " ju " job " jj " déjà terminé")
			} else {
			    erreur("user " ju " job " jj " pas commencé")
			}
		    }
	END	    { NR = "fin" }
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
    msg=$(awk -f $TMP.awk -v max="$m" -v m="$m" -v n="$n" -v p="$p" -v tmax="$tmax" "$TMP.out")
    [ $? != 0 ] && fail "awk terminé en erreur pour m=$m n=$n p=$p tmax=$tmax : $msg"
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
    $PROG 0 1 1 1   > $TMP.out 2> $TMP.err	&& fail "m=0 invalide"
    verifier_stderr
    $PROG 1 0 1 1   > $TMP.out 2> $TMP.err	&& fail "n=0 invalide"
    verifier_stderr
    $PROG 1 1 -1 1  > $TMP.out 2> $TMP.err	&& fail "p=-1 invalide"
    verifier_stderr
    $PROG 1 1 -1 1  > $TMP.out 2> $TMP.err	&& fail "tmax=-1 invalide"
    verifier_stderr
}

##############################################################################
# Tests basiques

run_test 2.1 "peu de contention (m=10 n=2 p=3 tmax=100)" && {
    lancer_timeout 5 $PROG 10 2 3 100	|| fail "erreur ccalc, cf $TMP.err"
    est_vide $TMP.err			|| fail "sortie sur stderr"
    verifier_sortie 10 2 3 100
}

run_test 2.2 "beaucoup de contention (m=10 n=7 p=500 tmax=10)" && {
    lancer_timeout 30 $PROG 10 7 500 10	|| fail "erreur ccalc, cf $TMP.err"
    est_vide $TMP.err			|| fail "sortie sur stderr"
    verifier_sortie 10 7 500 10
}

##############################################################################
# Test valgrind

run_test 3.1 "valgrind" && {
    tester_valgrind $PROG 10 2 3 100
}
