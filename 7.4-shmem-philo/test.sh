#!/bin/sh

# Chemins des exécutables
PROG_PHILO=${PROG_PHILO:=./philo}
PROG_TABLE=${PROG_TABLE:=./table}
PROG_PHILO_INTERB=${PROG_PHILO_INTERB:=./philo-interb}
PROG_TABLE_INTERB=${PROG_TABLE_INTERB:=./table-interb}
PROG_PHILO_TERM=${PROG_PHILO_TERM:=./philo-term}
PROG_TABLE_TERM=${PROG_TABLE_TERM:=./table-term}

# lire les variables et fonctions communes
. ../test-inc.sh

# en début de test, on veut nettoyer un peu plus que d'habitude
NETTOYER=nettoyer_et_ps

# vérifie que la sortie est correcte
# $1 = fichier sortie
# $2 = numéro de philosophe
# $3 = nb de repas
verifier_sortie ()
{
    [ $# != 3 ] && fail "ERREUR SYNTAXE verifier_sortie"
    local out="$1" p="$2" nrepas="$3"
    local nl msg

    nl=$(wc -l < "$out")
    [ $nl != "$nrepas" ] && fail "nb lignes ($nl) invalide dans '$out' (!= $nrepas)"

    cat > $TMP.awk <<'EOF'
	BEGIN		{ pvu = -1 }
	/^[0-9]+ : je mange$/ {
		    if (p != -1 && p != $1)
			erreur("numéro philosophe invalide")
		      if (pvu != -1 && pvu != $1)
			erreur("numéro philosophe différent")
		      next
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
    msg=$(awk -f $TMP.awk -v p="$p" -v nrepas="$nrepas" "$out")
    [ $? != 0 ] && fail "awk terminé en erreur pour p=$p nrepas=$nrepas : $msg"
}

# nettoyage façon karscher
nettoyer_et_ps ()
{
    local prog

    nettoyer
    for prog in $PROG_PHILO $PROG_TABLE \
    		$PROG_PHILO_INTERB $PROG_TABLE_INTERB \
		$PROG_PHILO_TERM $PROG_TABLE_TERM
    do
	killall $prog 2> /dev/null
    done
}

# tester les arguments (quel que soit le programme)
# $1 = le programme à tester
tester_arg ()
{
    local prog="$1"

    lancer_timeout 2 $prog		&& fail "$prog: pas assez d'arg"
    verifier_usage

    lancer_timeout 2 $prog 1 2		&& fail "$prog: trop d'arg"
    verifier_usage

    lancer_timeout 2 $prog 0 		&& fail "$prog: arg = 0"
    verifier_stderr

    lancer_timeout 2 $prog -1 		&& fail "$prog: arg = -1"
    verifier_stderr
}

##############################################################################
# Version avec interblocage
##############################################################################

##############################################################################
# Tests d'erreur sur les arguments

run_test 1.1 "arguments table" && {
    tester_arg $PROG_TABLE
}

run_test 1.2 "arguments philo" && {
    tester_arg $PROG_PHILO
}

run_test 1.3 "comportement de table avec une shmem pré-existante" && {
    lancer_timeout 2 $PROG_TABLE 5	|| fail "erreur au démarrage 1"
    # avec un deuxième démarrage, il faudrait que le segment de mémoire
    # partagé soit réinitialisé
    lancer_timeout 2 $PROG_TABLE 5	|| fail "erreur au démarrage 2"
}

##############################################################################
# Tests basiques

run_test 2.1 "test 5 philosophes sans interblocage" && {
    NPHILO=5
    NREPAS=10
    $PROG_TABLE $NPHILO > $TMP.out 2> $TMP.err	|| fail "erreur table"
    # si chaque philosophe est lancé lorsque les précédents sont
    # terminés, il ne peut pas y avoir d'interblocage
    for i in $(seq $NPHILO)
    do
        lancer_timeout 1 $PROG_PHILO $NREPAS	|| fail "erreur philo $i"
        verifier_sortie $TMP.out $((i-1)) 10
    done
}

run_test 2.2 "test 3 philosophes avec interblocage" && {
    NPHILO=3
    NREPAS=10000	# avec ça, on aura très probablement un interblocage
    $PROG_TABLE $NPHILO > $TMP.out 2> $TMP.err	|| fail "erreur table"
    # si chaque philosophe est lancé lorsque les précédents sont
    # terminés, il ne peut pas y avoir d'interblocage
    lpid=""
    for i in $(seq $NPHILO)
    do
        $PROG_PHILO $NREPAS	> $TMP.out$i 2> $TMP.err$i &
        lpid="$lpid $!"
    done
    sleep 2
    # s'il reste au moins un processus, c'est qu'il n'y a pas eu d'interblocage
    termines=""
    for pid in $lpid
    do
        if ! ps_existe $pid
        then termines="$termines $pid"
        fi
    done
    [ "$termines" = "" ] || fail "pas d'interblocage : pid $termines terminés"
}

##############################################################################
# Version sans interblocage
##############################################################################

##############################################################################
# Tests d'erreur sur les arguments

run_test 3.1 "arguments table-interb" && {
    tester_arg $PROG_TABLE_INTERB
}

run_test 3.2 "arguments philo-interb" && {
    tester_arg $PROG_PHILO_INTERB
}

##############################################################################
# Tests basiques

run_test 4.1 "test 3 philosophes" && {
    NPHILO=3
    NREPAS=10000	# avec ça, on aura très probablement un interblocage
    $PROG_TABLE_INTERB $NPHILO > $TMP.out 2> $TMP.err || fail "erreur table-interb"
    # si chaque philosophe est lancé lorsque les précédents sont
    # terminés, il ne peut pas y avoir d'interblocage
    lpid=""
    for i in $(seq $NPHILO)
    do
        $PROG_PHILO_INTERB $NREPAS	> $TMP.out$i 2> $TMP.err$i &
        lpid="$lpid $!"
    done
    sleep 2
    # s'il reste au moins un processus, c'est qu'il n'y a pas eu d'interblocage
    i=1
    reste=""
    for pid in $lpid
    do
        if ps_existe $pid
        then reste="$reste $pid"
        else wait $pid || fail "erreur terminaison philo pid=$pid, cf $TMP.err$i"
        fi
        i=$((i+1))
    done
    [ "$reste" = "" ] || fail "interblocage : reste pid $termines"
    for i in $(seq $NPHILO)
    do
        verifier_sortie $TMP.out$i -1 $NREPAS
    done
}

run_test 4.2 "test unicité du numéro de philosophe (peu discriminant)" && {
    NPHILO=300
    NREPAS=1
    $PROG_TABLE_INTERB $NPHILO > $TMP.out 2> $TMP.err || fail "erreur table-interb"
    # si chaque philosophe est lancé lorsque les précédents sont
    # terminés, il ne peut pas y avoir d'interblocage
    lpid=""
    for i in $(seq $NPHILO)
    do
        $PROG_PHILO_INTERB $NREPAS	> $TMP.out$i 2> $TMP.err$i &
        lpid="$lpid $!"
    done
    sleep 2
    # s'il reste au moins un processus, c'est qu'il n'y a pas eu d'interblocage
    i=1
    reste=""
    for pid in $lpid
    do
        if ps_existe $pid
        then reste="$reste $pid"
        else wait $pid || fail "erreur terminaison philo pid=$pid, cf $TMP.err$i"
        fi
        i=$((i+1))
    done
    [ "$reste" = "" ] || fail "interblocage : reste pid $termines"
    for i in $(seq $NPHILO)
    do
        verifier_sortie $TMP.out$i -1 $NREPAS
    done
    # vérifier que les numéros de philosophe sont tous différents
    cat $TMP.out?* | sort > $TMP.out
    cat > $TMP.2.awk <<'EOF'
    	BEGIN	{ min = np ; max = -1 }
    	/^[0-9]+ : je mange$/ {
    		    p = $1
    		    vu [p]++
    		    if (vu [p] > 1)
    			erreur("philo " p " vu plusieurs fois")
    		    if (p < min)
    			p = min
    		    if (p > max)
    			p = max
    		}
    	END	{
    		    if (min < 0)
    			erreur("philo " min " trop petit")
    		    if (max >= np)
    			erreur("philo " max " trop grand")
    		    for (p = min ; p < max ; p++)
    			if (vu [p] == 0)
    			    erreur("philo " p " pas vu")
    		}
    	function erreur(msg)
    	{
    	    if (err != 1) print msg
    	    err = 1
    	    exit 1
    	}
EOF
    msg=$(awk -f $TMP.2.awk -v np="$NPHILO" $TMP.out)
    [ $? != 0 ] && fail "problème d'unicité du numéro de philosophe: $msg"
}

##############################################################################
# Version avec terminaison
##############################################################################

##############################################################################
# Tests d'erreur sur les arguments

run_test 5.1 "arguments table-term" && {
    tester_arg $PROG_TABLE_TERM
}

run_test 5.2 "arguments philo-term" && {
    tester_arg $PROG_PHILO_TERM
}

##############################################################################
# Tests basiques

run_test 6.1 "test 3 philosophes" && {
    NPHILO=5
    NREPAS=1000	# avec ça, on aura très probablement un interblocage
    $PROG_TABLE_TERM $NPHILO > $TMP.tout 2> $TMP.terr &
    pidtable=$!
    sleep 1				# laisser à table le temps de démarrer
    # si chaque philosophe est lancé lorsque les précédents sont
    # terminés, il ne peut pas y avoir d'interblocage
    lpid=""
    for i in $(seq $NPHILO)
    do
        ps_existe $pidtable || fail "$PROG_TABLE_TERM terminé trop tôt (i=$i)"
        $PROG_PHILO_TERM $NREPAS	> $TMP.out$i 2> $TMP.err$i &
        lpid="$lpid $!"
    done
    sleep 2
    # s'il reste au moins un processus, c'est qu'il n'y a pas eu d'interblocage
    i=1
    reste=""
    for pid in $lpid
    do
        if ps_existe $pid
        then reste="$reste $pid"
        else wait $pid || fail "erreur terminaison philo pid=$pid, cf $TMP.err$i"
        fi
        i=$((i+1))
    done
    [ "$reste" = "" ] || fail "interblocage : reste pid $termines"
    for i in $(seq $NPHILO)
    do
        verifier_sortie $TMP.out$i -1 $NREPAS
    done
    ps_existe $pidtable && fail "$PROG_TABLE_TERM ne s'est pas terminé"
    wait $pidtable || fail "erreur terminaison $PROG_TABLE_TERM, cf $TMP.terr"
}
