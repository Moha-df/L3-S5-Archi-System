#!/bin/sh

# Chemins des exécutables
PROG_CTRL=${PROG_CTRL:=./ctrl}
PROG_AREF=${PROG_AREF:=./aref}
PROG_RREF=${PROG_RREF:=./rref}
PROG_AJOUT=${PROG_AJOUT:=./ajout}
PROG_RETRAIT=${PROG_RETRAIT:=./retrait}
PROG_LISTE=${PROG_LISTE:=./liste}

# lire les variables et fonctions communes
. ../test-inc.sh

# en début de test, on veut nettoyer un peu plus que d'habitude
NETTOYER=nettoyer_et_ps

# délai (en sec) pour attendre que les programmes se lancent
DELAI=1			# mettre 2 pour des machines très très très lentes

# vérifie que les références dans le stock sont correctes
# $1 = fichier contenant le stock attendu
# $2 = msg
verifier_stock ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE verifier_stock"
    local stock="$1" msg="$2"

    $PROG_CTRL dump > $TMP.dump 2> $TMP.err	|| fail "ctrl dump"

    # $TMP.diff = différences ("+" = réf en trop, "-" = réf manquante)

    sed -n 's/.* réf \([^ ]*\) qté \([^ ]*\)$/\1 \2/p' $TMP.dump \
	| sort -n \
	| diff -u - $stock > $TMP.diff \
	    || fail "stock non conforme ($msg), cf $TMP.diff"
}

# nettoyage façon karscher
nettoyer_et_ps ()
{
    local prog

    nettoyer
    for prog in $PROG_CTRL $PROG_AREF $PROG_RREF \
    		$PROG_AJOUT $PROG_RETRAIT $PROG_LISTE
    do
	killall $prog 2> /dev/null
    done
    $PROG_CTRL destroy > /dev/null 2>&1		# ignorer le résultat
    if [ -d /dev/shm ]
    then rm -f /dev/shm/*magasin
    fi
}

# initialiser le segment de mémoire partagée
# $1 = nb de références
init_shmem ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE init_shmem"

    local nref="$1"

    nettoyer_et_ps
    $PROG_CTRL init $nref > $TMP.out 2> $TMP.err || fail "création / $nref réf"
}

# tester que le programme fourni (avec ses arguments) donne bien une erreur
# $1 = message d'erreur
# $2 et suivants = le programme et ses arguments (sans espaces) éventuels
tester_erreur ()
{
    [ $# -le 1 ] && fail "ERREUR SYNTAXE tester_erreur"

    local msg="$1"
    shift

    lancer_timeout 1 $*		&& fail "$1: exit != 0 ($msg)"
    verifier_stderr
}

# tester des arguments invalides
# $1 = message d'erreur
# $2 et suivants = le programme et ses arguments (sans espaces) éventuels
tester_usage ()
{
    [ $# -le 1 ] && fail "ERREUR SYNTAXE tester_usage"

    local msg="$1"
    shift

    tester_erreur "$msg" $*
    verifier_usage
}

##############################################################################
# Tests du programme de contrôle

run_test 1.1 "arguments de ctrl" && {
    tester_usage "arg toto" $PROG_CTRL toto
    tester_usage "init sans arg" $PROG_CTRL init
    tester_usage "init avec arg nul" $PROG_CTRL init 0
    tester_usage "destroy avec arg" $PROG_CTRL destroy 1
    tester_usage "dump avec arg" $PROG_CTRL dump 1
}

run_test 1.2 "création shmem" && {
    nettoyer_et_ps
    # on suppose que le segment est supprimé : récupérer la liste des shmem
    if [ -d /dev/shm ]
    then liste1=$(ls /dev/shm | sort)
    fi
    # créer le segment initialement
    $PROG_CTRL init 3 > $TMP.out 2> $TMP.err	|| fail "création initiale"
    # la liste des shmem est-elle bien modifiée ?
    if [ -d /dev/shm ]
    then
        liste2=$(ls /dev/shm | sort)
        [ x"$liste1" = x"$liste2" ] && fail "aucun shmem n'est créé"
    fi
}

run_test 1.3 "création shmem déjà existant" && {
    # créer le segment initialement
    $PROG_CTRL init 3 > $TMP.out 2> $TMP.err	|| fail "création initiale"
    # on ne supprime pas la mémoire partagée : il doit y avoir une erreur
    $PROG_CTRL init 3 > $TMP.out 2> $TMP.err	&& fail "shmem existe déjà"
}

run_test 1.4 "suppression shmem" && {
    # créer un segment
    $PROG_CTRL init 3 > $TMP.out 2> $TMP.err	|| fail "création initiale"
    # récupérer la liste des shmem
    if [ -d /dev/shm ]
    then liste1=$(ls /dev/shm | sort)
    fi
    # suppression du segment
    $PROG_CTRL destroy > $TMP.out 2> $TMP.err	|| fail "erreur suppression"
    # la liste des shmem est-elle bien modifiée ?
    if [ -d /dev/shm ]
    then
        liste2=$(ls /dev/shm | sort)
        [ x"$liste1" = x"$liste2" ] && fail "aucun shm n'a été supprimé"
    fi
}

run_test 1.5 "suppression shmem inexistant" && {
    tester_erreur "suppression shmem" $PROG_CTRL destroy
}

run_test 1.6 "ctrl dump sur shmem inexistant" && {
    tester_erreur "dump shmem inexistant" $PROG_CTRL dump
}

run_test 1.7 "ctrl dump" && {
    # créer un shmem
    $PROG_CTRL init 3 > $TMP.out 2> $TMP.err	|| fail "création initiale"
    $PROG_CTRL dump > $TMP.out 2> $TMP.err	|| fail "dump shmem inexistant"
    grep -q "^LIBRES " $TMP.out || fail "pas trouvé 'LIBRES' dans le dump"
    grep -q "suiv -1 " $TMP.out || fail "pas trouvé '-1' dans le dump"
    $PROG_CTRL destroy > $TMP.out 2> $TMP.err	# ignorer le résultat
}

##############################################################################
# Ajout et suppression de références

run_test 2.1 "arguments aref/rref" && {
    init_shmem 2
    tester_erreur "aref sans arg"	$PROG_AREF
    init_shmem 2
    tester_erreur "aref arg=0"		$PROG_AREF 0
    init_shmem 2
    tester_erreur "rref sans arg"	$PROG_RREF
    init_shmem 2
    tester_erreur "rref arg=0"		$PROG_RREF 0
}

run_test 2.2 "aref" && {
    init_shmem 2
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    lancer_timeout 1 $PROG_AREF 200		|| fail "aref 200"
    $PROG_CTRL dump > $TMP.out 2> $TMP.err	|| fail "ctrl dump"
    grep -q "réf 100 qté 0$" $TMP.out		|| fail "pas trouvé la réf 100"
    grep -q "réf 200 qté 0$" $TMP.out		|| fail "pas trouvé la réf 200"
    tester_erreur "ajout 3e ref"	$PROG_AREF 300
}

run_test 2.3 "aref sur référence redondante" && {
    init_shmem 2
    lancer_timeout 1 $PROG_AREF 100			|| fail "aref 100"
    tester_erreur "aref 100 déjaà fait"	$PROG_AREF 100
}

run_test 2.4 "rref" && {
    init_shmem 3
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    lancer_timeout 1 $PROG_AREF 200		|| fail "aref 200"
    $PROG_CTRL dump > $TMP.out 2> $TMP.err	|| fail "ctrl dump"
    grep -q "réf 100 qté 0$" $TMP.out		|| fail "pas trouvé la réf 100"
    grep -q "réf 200 qté 0$" $TMP.out		|| fail "pas trouvé la réf 200"
    lancer_timeout 1 $PROG_RREF 100		|| fail "rref 100"
    $PROG_CTRL dump > $TMP.out 2> $TMP.err	|| fail "ctrl dump"
    grep -q "réf 100 qté 0$" $TMP.out		&& fail "100 est toujours là"
    grep -q "réf 200 qté 0$" $TMP.out	|| fail "réf 200 non trouvée après rref"
}

run_test 2.5 "rref sur référence inexistante" && {
    init_shmem 3
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    lancer_timeout 1 $PROG_AREF 200		|| fail "aref 200"
    tester_erreur "rref 300 inexistant"	$PROG_RREF 300
}

run_test 2.6 "aref/rref aux limites" && {
    init_shmem 3
    # remplir la liste à fond
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    lancer_timeout 1 $PROG_AREF 200		|| fail "aref 200"
    lancer_timeout 1 $PROG_AREF 300		|| fail "aref 300"
    # supprimer le dernier ajouté
    lancer_timeout 1 $PROG_RREF 300		|| fail "rref 300"

    init_shmem 3
    # remplir la liste à fond
    lancer_timeout 1 $PROG_AREF 400		|| fail "aref 400"
    lancer_timeout 1 $PROG_AREF 500		|| fail "aref 500"
    lancer_timeout 1 $PROG_AREF 600		|| fail "aref 600"
    # supprimer le premier ajouté
    lancer_timeout 1 $PROG_RREF 400		|| fail "rref 400"

    init_shmem 3
    # remplir la liste à fond
    lancer_timeout 1 $PROG_AREF 700		|| fail "aref 700"
    lancer_timeout 1 $PROG_AREF 800		|| fail "aref 800"
    lancer_timeout 1 $PROG_AREF 900		|| fail "aref 900"
    # supprimer celui du milieu
    lancer_timeout 1 $PROG_RREF 800		|| fail "rref 800"
}

# fonction commune aux tests 2.7 et 2.8
# $1 = nb de processus
# $2 = nb de réf par processus
construire_stock_27 ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE construire_stock"
    local p=$1 n=$2

    init_shmem $((p*n))
    LPID=""
    for i in $(seq 1 $p)
    do
        # i = 1 : aref 1000 1001 1002 ... 1999
        prem=$((i*n))
        dern=$(( (i+1)*n - 1))
        $PROG_AREF $(seq $prem $dern) > $TMP.out$i 2> $TMP.err$i &
        LPID="$LPID $!"
    done
    echo "$LPID" > $TMP.lpid	# laisser une trace pour le debug
    sleep $DELAI		# 1 sec pour que les aref se terminent
    i=1
    for pid in $LPID
    do
        ps_existe $pid	&& fail "aref $i (pid=$pid) non terminé"
        wait $pid	|| fail "aref $i (pid=$pid) mal terminé => $TMP.err$i"
        i=$((i+1))
    done
}

run_test 2.7 "accès concurrents aref" && {
    P=10			# 10 processus
    N=1000			# 100 réf par processus
    construire_stock_27 $P $N
    # $TMP.ref contient les références attendues
    # $TMP.diff contiendra les différences ("+": réf en trop, "-": manquante)
    seq $N $(( (P+1)*N - 1 )) | sed 's/$/ 0/' > $TMP.ref
    verifier_stock $TMP.ref "pb concurrence aref"
}

run_test 2.8 "accès concurrents rref" && {
    # reconstruire le stock comme dans le test précédent
    P=10			# 10 processus
    N=1000			# 100 réf par processus
    construire_stock_27 $P $N

    # supprimer les fichiers en trop pour ne pas avoir trop de
    # fichiers à examiner en cas d'erreur
    rm -f $TMP.*

    # supprimer les références
    LPID=""
    for i in $(seq 1 $P)
    do
        # i = 1 => aref 1000 1001 1002 ... 1999
        # i = 2 => aref 2000 ... 2999
        prem=$((i*N))
        dern=$(( (i+1)*N - 1))
        $PROG_RREF $(seq $prem $dern) > $TMP.out$i 2> $TMP.err$i &
        LPID="$LPID $!"
    done
    echo "$LPID" > $TMP.lpid	# laisser une trace pour le debug
    sleep $DELAI
    i=1
    for pid in $LPID
    do
        ps_existe $pid	&& fail "rref $i (pid=$pid) non terminé"
        wait $pid	|| fail "rref $i (pid=$pid) mal terminé => $TMP.err$i"
        i=$((i+1))
    done
    # extraire les références qui restent
    $PROG_CTRL dump > $TMP.out 2> $TMP.err	|| fail "ctrl dump"
    # il ne doit plus y avoir aucune référence
    n=$(grep " vide$" $TMP.out | wc -l)
    [ $n != $((N*P)) ]		&& fail "il reste des références dans $TMP.out"
}

##############################################################################
# Ajout et suppression d'articles

run_test 3.1 "arguments ajout/retrait" && {
    init_shmem 3
    # quelques articles pour meubler la shmem
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    lancer_timeout 1 $PROG_AREF 200		|| fail "aref 200"
    # arguments ajout
    tester_erreur "ajout sans arg"		$PROG_AJOUT
    tester_erreur "ajout 1 arg"			$PROG_AJOUT 100
    tester_erreur "ajout ref=0"			$PROG_AJOUT 0 10
    tester_erreur "ajout ref inexistante"	$PROG_AJOUT 500 10
    # arguments retrait
    tester_erreur "retrait sans arg"		$PROG_RETRAIT
    tester_erreur "retrait 1 arg"		$PROG_RETRAIT 100
    tester_erreur "retrait ref=0"		$PROG_RETRAIT 0 10
    tester_erreur "retrait ref inexistante"	$PROG_RETRAIT 500 10
}

construire_stock_32 ()
{
    init_shmem 3
    # quelques articles pour meubler la shmem
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    lancer_timeout 1 $PROG_AREF 200		|| fail "aref 200"
    # ajout simple
    lancer_timeout 1 $PROG_AJOUT 100 10 200 20	|| fail "ajout 100 10 200 20"
}

run_test 3.2 "ajout" && {
    construire_stock_32
    # vérification du stock
    cat <<EOF > $TMP.ref
100 10
200 20
EOF
    verifier_stock $TMP.ref "ajout 100 10 200 20"
}

construire_stock_33 ()
{
    construire_stock_32
    lancer_timeout 1 $PROG_RETRAIT 100 5 200 10
}

run_test 3.3 "retrait sans attente" && {
    construire_stock_33
    # vérification du stock
    cat <<EOF > $TMP.ref
100 5
200 10
EOF
    verifier_stock $TMP.ref "retrait 100 5 200 10"
}

run_test 3.4 "retrait avec attente" && {
    construire_stock_33
    $PROG_RETRAIT 100 10 > $TMP.rout 2> $TMP.rerr &
    PID=$!
    sleep 0.2
    # retrait a pris les 5 disponibles, il en manque encore 5
    ps_existe $PID			|| fail "retrait (pid=$PID) a disparu A"
    lancer_timeout 1 $PROG_AJOUT 100 2	|| fail "ajout A"
    sleep 0.2
    # ajout en a ajouté 2, retrait les a pris, il en manque encore 3
    ps_existe $PID			|| fail "retrait (pid=$PID) a disparu B"
    lancer_timeout 1 $PROG_AJOUT 100 5	|| fail "ajout B"
    sleep 0.2
    # c'est bon, retrait doit être terminé
    ps_existe $PID			&& fail "retrait (pid=$PID) non terminé"
    wait $PID				|| fail "retrait terminé en erreur"
    cat <<EOF > $TMP.ref
100 2
200 10
EOF
    verifier_stock $TMP.ref "retrait 100 2 200 10"
}

run_test 3.5 "retraits multiples avec attente" && {
    init_shmem 3
    # quelques articles pour meubler la shmem
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    lancer_timeout 1 $PROG_AREF 200		|| fail "aref 200"
    lancer_timeout 1 $PROG_AREF 300		|| fail "aref 200"
    # ajout simple
    lancer_timeout 1 $PROG_AJOUT 100 10 200 10	|| fail "ajout 100 10 200 10"
    lancer_timeout 1 $PROG_AJOUT 300 10		|| fail "ajout 300 10"
    # lancer retrait1
    $PROG_RETRAIT 100 20 > $TMP.rout1 2> $TMP.rerr1 &
    PID1=$!
    # lancer retrait3 (pas de retrait2)
    $PROG_RETRAIT 300 20 > $TMP.rout3 2> $TMP.rerr3 &
    PID3=$!
    sleep 0.2
    # aucun des deux n'est satisfait : attente
    ps_existe $PID1		|| fail "retrait 100 (pid=$PID1) a disparu A"
    ps_existe $PID3		|| fail "retrait 300 (pid=$PID3) a disparu"
    # on donne à retrait3 ce qu'il attendait
    lancer_timeout 1 $PROG_AJOUT 300 15	|| fail "ajout 300 15"
    sleep 0.2
    ps_existe $PID1		|| fail "retrait 100 (pid=$PID1) a disparu B"
    ps_existe $PID3		&& fail "retrait 300 (pid=$PID3) non terminé"
    wait $PID3 			|| fail "retrait 300 terminé en erreur"
    # on donne à retrait1 ce qu'il attendait
    lancer_timeout 1 $PROG_AJOUT 100 17	|| fail "ajout 100 17"
    sleep 0.2
    ps_existe $PID1		&& fail "retrait 100 (pid=$PID1) non terminé"
    wait $PID1 			|| fail "retrait 100 terminé en erreur"
    cat <<EOF > $TMP.ref
100 7
200 10
300 5
EOF
    verifier_stock $TMP.ref "pb de concurrence"
}

run_test 3.6 "retraits concurrents" && {
    P=10			# 10 processus
    init_shmem 3
    # un article pour meubler la shmem
    lancer_timeout 1 $PROG_AREF 100		|| fail "aref 100"
    # vérification juste pour voir
    cat <<EOF > $TMP.ref
100 0
EOF
    verifier_stock $TMP.ref "juste pour voir"
    # lancer $P "retrait" simultanés
    LPID=""
    for i in $(seq 1 $P)
    do
        $PROG_RETRAIT 100 2 > $TMP.out$i 2> $TMP.err$i &
        LPID="$LPID $!"
    done
    echo "$LPID" > $TMP.lpid	# laisser une trace pour le debug
    sleep $DELAI
    # ils viennent de démarrer, aucun n'a encore pu se terminer
    for pid in $LPID
    do
        ps_existe $pid		|| fail "retrait $i (pid=$pid) a disparu A"
        i=$((i+1))
    done
    # débloquer entre 1 et 2 "retrait"
    for i in $(seq 1 3)
    do
        lancer_timeout 1 $PROG_AJOUT 100 1 || fail "ajout 100 $i"
    done
    # il doit rester entre $P-1 et $P "retrait"
    n=0
    for pid in $LPID
    do
        if ps_existe $pid
        then n=$((n+1))
        fi
    done
    [ $n -ge $((P-1)) ]	|| fail "il ne reste que $n 'retrait' en activité"
    # débloquer les autres retrait, sauf le dernier
    for i in $(seq 4 $((P*2 - 1)) )
    do
        lancer_timeout 1 $PROG_AJOUT 100 1 || fail "ajout 100 $i"
    done
    # il doit rester juste 1 "retrait"
    n=0
    for pid in $LPID
    do
        if ps_existe $pid
        then n=$((n+1))
        fi
    done
    [ $n != 1 ]	&& fail "il ne devrait rester que 1 'retrait' en activité ($n)"
    # débloquer le dernier
    lancer_timeout 1 $PROG_AJOUT 100 5 || fail "ajout 100 (dernier)"
    i=1
    for pid in $LPID
    do
        ps_existe $pid	&& fail "retrait $i (pid=$pid) non terminé"
        wait $pid	|| fail "rertait $i (pid=$pid) mal terminé => $TMP.err$i"
        i=$((i+1))
    done
    cat <<EOF > $TMP.ref
100 4
EOF
    verifier_stock $TMP.ref "pb de concurrence"
}

##############################################################################
# Liste

run_test 3.7 "liste" && {
    init_shmem 5
    # des articles pour meubler la shmem (attention à l'ordre)
    lancer_timeout 1 $PROG_AREF 100 200 400 300			|| fail "aref"
    lancer_timeout 1 $PROG_AJOUT 100 10 200 20 300 30 400 40	|| fail "ajout"
    # normalement, il y a interblocage à ce niveau
    lancer_timeout 1 $PROG_LISTE				|| fail "liste" 
    # vérification du format
    cat <<EOF > $TMP.ref
100 10
200 20
400 40
300 30
EOF
    diff -u $TMP.ref $TMP.out > $TMP.diff	|| fail "résultat de liste incorrect"
}
