#!/bin/sh

#
# Définitions de fonctions et de variables communes à tous les
# scripts de tests.
#
# Note sur l'utilisation des scripts de tests (scripts test*.sh dans les
# répertoires des exercices) :
# Syntaxe :
# 	./test.sh [-h] [-v] [-t] [-k] [numtest ...]
#
# Par défaut, le script exécute tous les tests et doit afficher
# "Tests ok" à la fin. Dans le cas contraire, le nom du tests
# échoué s'affiche, et les fichiers utilisés par le test sont
# laissés dans /tmp/test*. Il est alors possible de les examiner.
#
# Il est également possible d'exécuter un ou plusieurs tests
# spécifiques. Par exemple, pour exécuter les tests 1.3 et 4.2
# il faut faire :
# 	./test.sh 1.3 4.2
#
# Pour avoir plus de détails sur ce que fait chaque test, il
# faut utiliser l'option -v (verbose). Il est conseillé de l'utiliser
# avec un test spécifique. Par exemple, pour examiner en détail
# ce que fait le test 2.5, il faut faire :
# 	./test -v 2.5
#
# L'option -h (help) rappelle la syntaxe
# L'option -t (terse) affiche le résultat des tests de façon sobre
# L'option -k (keep) conserve les fichiers même si le dernier test réussit
# L'option -d (duration) n'exécute pas les tests, mais retourne une estimation
# 	de la durée maximum, pour utilisation par des scripts appelants
#

TMP=${TMP:=/tmp/test.$USER}		# chemin des logs de test

# Durée maximum (par défaut) de chaque test individuel
MAXDUR=${MAXDUR:=2}			# en secondes

# Conserver la locale d'origine
OLDLOCALE=$(locale)

# Pour éviter les différences de comportement suivant la locale courante
LC_ALL=POSIX
export LC_ALL

set -u					# erreur si accès variable non définie

# aucun test n'est en cours
TEST_EN_COURS=""			# sinon : numéro de test

# fonction à appeler pour le nettoyage à la fin de chaque test (réussi)
NETTOYER=nettoyer

# durée estimée (pour l'option -d)
DUREE_ESTIMEE=0

if [ "${BASH:=heureusement-non}" != "heureusement-non" ]
then
    (
	echo "Vous exécutez ce script avec 'bash', non compatible avec POSIX"
	echo "Il y a des problèmes d'affichage avec ce Shell."
	echo "Préférez 'dash' ou un autre shell : dash ./test.sh ...."
    ) >&2
fi

##############################################################################
# Mécanique de gestion des tests : échec, réussite, tests à ne pas faire, etc.

# pour éviter un message disgrâcieux en cas d'appel à "fail" lors de
# l'initialisation
TEST_EN_COURS="init"

# Il ne faudrait jamais appeler cette fonction...
# argument : message d'erreur
fail ()
{
    if [ "$VERBOSE" = vrai ]
    then set +x				# supprimer le mode verbeux si besoin
    fi

    local msg="$1"

    trap "" EXIT			# annuler l'action automatique de fin

    case "$TEST_EN_COURS" in
	("")
	    echo "ERREUR INTERNE : 'fail' appelée sans test en cours" >&2
	    echo "MESSAGE ORIGINAL : $msg" >&2
	    ;;
	(init)
	    echo "Erreur lors de l'initialisation :"
	    echo "    $msg"
	    ;;
	(*)
	    if [ $TERSE = vrai ]
	    then
		echo "fail $TEST_EN_COURS"
		exit 1
	    fi

	    echo FAIL			# aie aie aie...
	    echo "Echec du test $TEST_EN_COURS"

	    echo "$msg"
	    echo "Voir les fichiers suivants :"
	    ls -dp $TMP* 2> /dev/null
	    ;;
    esac
    exit 1
}

# Termine les affichages s'il y a un test en cours
success ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE success"

    if [ "$DUREE" = faux ] && [ "$TEST_EN_COURS" != "" ] && [ "$TEST_EN_COURS" != init ]
    then
	if [ "$TERSE" = vrai ]
	then echo "success $TEST_EN_COURS"
	else echo "OK"
	fi
	TEST_EN_COURS=""
    fi
}

# Action implicite à la fin "normale" du script
fin ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE fin"

    if [ "$DUREE" = vrai ]
    then
	# afficher la durée estimée (on n'a pas fait les tests)
	echo $DUREE_ESTIMEE
	exit 0
    fi

    if [ x"$TEST_EN_COURS" != "" ]
    then
	success
	# faut-il conserver les fichiers ?
	if [ "$KEEP" != keep ]
	then
	    # La fonction "nettoyer", ou la fonction spécifiée dans le script
	    # de test, au cas où on veuille en faire plus que "nettoyer"
	    $NETTOYER
	fi
    fi
    if [ x"$TESTS_A_FAIRE" != x ]
    then
	if [ $(echo "$TESTS_A_FAIRE" | wc -l) = 2 ]
	then s=""
	else s="s"
	fi
	echo "Tests non trouvés :" $TESTS_A_FAIRE >&2
	exit 2
    fi
    if [ "$TESTS_TOUS" = vrai ] && [ "$TERSE" != vrai ]
    then echo "Tests ok"
    fi
    exit 0
}

# Longueur (en nb de caractères, pas d'octets) d'une chaîne UTF-8
# Note : la locale doit être en UTF-8
strlen ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE strlen"
    local str="$1"
    (
	eval $OLDLOCALE
	printf "%s" "$str" | wc -m
    )
}

# Décide s'il faut faire un test et si c'est le cas, l'annonce
# $1 = numéro du test
# $2 = intitulé
# $3 (optionnel) = durée maximum autorisée pour le test (défaut = $MAXDUR)
# retourne : vrai ou faux s'il ne faut pas le faire
run_test ()
{
    if [ "$VERBOSE" = vrai ]
    then set +x		# supprimer le mode verbeux si besoin
    fi

    [ $# != 2 -a $# != 3 ] && fail "ERREUR SYNTAXE run_test"
    local num="$1" msg="$2"

    # a-t-on défini une limite de temps ou faut-il utiliser celle par défaut ?
    local maxdur=$MAXDUR
    if [ $# = 3 ]
    then maxdur="$3"
    fi

    success		# terminer le test en cours s'il y a besoin

    local regexp="^$(echo "$num" | sed 's/\./\\./')$"

    # test de cohérence : on ne devrait pas avoir deux fois le même numéro
    if echo "$TESTS_VUS" | grep -q "$regexp"
    then fail "ERREUR INTERNE : test $num déjà vu"
    else
	TESTS_VUS="$TESTS_VUS
$num"
    fi

    # faut-il exécuter le test ?
    if [ $TESTS_TOUS != vrai ] && ! echo "$TESTS_A_FAIRE" | grep -q "$regexp"
    then return 1	# sortir tout de suite, ne pas faire le test
    fi

    # ok, il faut faire le test. Le retirer des tests à faire
    TESTS_A_FAIRE="$(echo "$TESTS_A_FAIRE" | grep -v "$regexp")"
    TEST_EN_COURS="$num"

    if [ "$DUREE" = vrai ]
    then
	DUREE_ESTIMEE=$((DUREE_ESTIMEE + maxdur))
	return 1	# on ne fait pas le test, on ne compte que la durée
    fi

    if [ "$TERSE" != vrai ]
    then
	local debut nbcar nbtirets

	# echo '\c', bien que POSIX, n'est pas supporté sur tous les Shell
	# POSIX recommande d'utiliser printf
	# Par contre, printf ne gère pas correctement les caractères Unicode
	# donc on est obligé de recourir à un subterfuge pour préserver
	# l'alignement des "OK"
	debut="Test $num - $msg"
	nbcar=$(strlen "$debut")
	nbtirets=$((80 - 6 - nbcar))
	printf "%s%-${nbtirets}.${nbtirets}s " "$debut" \
	    "...................................................................."

	if [ "$VERBOSE" = vrai ]
	then
	    echo
	    set -x
	fi
    fi

    # La fonction "nettoyer", ou la fonction spécifiée dans le script
    # de test, au cas où on veuille en faire plus que "nettoyer"
    $NETTOYER		# démarrer un test avec un espace vierge

    return 0
}

# Le nettoyage façon karscher : il ne reste plus une trace après...
nettoyer ()
{
    rm -rf $TMP.*
}

##############################################################################
# Fonctions souvent utilisées par les scripts de test

# Teste si le fichier est vide (ne fait que tester, pas d'erreur renvoyée)
est_vide ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE est_vide"
    local fichier="$1"
    test $(wc -c < "$fichier") = 0		# 0 octet
}

# Vérifie que le message d'erreur est envoyé sur la sortie d'erreur
# et non sur la sortie standard
verifier_stderr ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE verifier_stderr"
    est_vide $TMP.err \
	&& fail "Le message d'erreur devrait être sur la sortie d'erreur$msg"
    est_vide $TMP.out \
	|| fail "Rien ne devrait être affiché sur la sortie standard$msg"
}

# Vérifie que le résultat est envoyé sur la sortie standard
# et non sur la sortie d'erreur
verifier_stdout ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE verifier_stdout"
    est_vide $TMP.out \
	&& fail "Le résultat devrait être sur la sortie d'erreur"
    est_vide $TMP.err \
	|| fail "Rien ne devrait être affiché sur la sortie d'erreur"
}

# Vérifie qu'il y a un message d'erreur et qu'il indique la bonne syntaxe
verifier_usage ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE verifier_usage"
    verifier_stderr
    grep -q "usage *: " $TMP.err \
	|| fail "Le message d'erreur devrait indiquer 'usage:...'"
}

# Récupère la durée en ms à partir de /usr/bin/time -p (POSIX)
# $1 = nom du fichier contenant le résultat de time -p
duree ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE duree"

    local fichier="$1"
    local duree_s

    duree_s=$(sed -n 's/real *//p' "$fichier" | sed 's/,/\./')
    echo "$duree_s*1000" | bc | sed 's/\..*//'
}

# Vérifie que le temps d'exécution est dans l'intervalle indiqué
# $1 = durée mesurée en ms (résultat de la fonction duree)
# $2 = durée attendue min
# $3 = durée attendue max
verifier_duree ()
{
    [ $# != 3 ] && fail "ERREUR SYNTAXE verifer_duree"

    local duree_ms="$1" min="$2" max="$3"

    if [ "$duree_ms" -lt "$min" ] || [ "$duree_ms" -gt "$max" ]
    then fail "durée incorrecte ($duree_ms ms) pas dans [$min,$max]"
    fi
}

# Génère un fichier pseudo-aléatoire
# $1 = nom
# $2 = taille (en multiples de 1 Mio)
generer_fichier_aleatoire ()
{
    [ $# != 2 ] && fail "ERREUR SYNTAXE generer_fichier_aleatoire"

    local nom="$1" taille="$2"
    local random=/dev/urandom

    if [ ! -c $random ]
    then echo "Pas de driver '$random'. Arrêt" >&2 ; exit 1
    fi

    dd if=$random of="$nom" bs=1024k count="$taille" 2> /dev/null
}

CMD_TIMEOUT=$(command -v -p timeout)
if [ x"$CMD_TIMEOUT" = x ]
then
    # La commande timeout n'est pas POSIX, elle peut exister
    # sur certains systèmes (Linux, FreeBSD), mais pas sur d'autres
    # (ex : MacOS). Si elle n'existe pas : il faut la simuler
    timeout ()
    {
	[ $# -le 1 ] && fail "ERREUR SYNTAXE timeout"
	local delai="$1" ; shift
	local pidcmd pidsleep exitcmd exitkill

	# lancer la commande en arrière plan
	"$@" &
	pidcmd=$!

	# lancer le chien de garde (watchdog) en arrière plan
	(
	    trap 'exit 127' TERM	# supprimer les affichages intempestifs
	    sleep $delai
	    kill -TERM $pidcmd
	) > /dev/null 2>&1 &
	pidsleep=$!

	# attendre la commande (et seulement la commande)
	wait $pidcmd
	exitcmd=$?

	if [ "$exitcmd" -ge 127 ]	# commande terminée par un signal ?
	then
	    if ps_existe $pidsleep
	    then
		# la commande a été terminée par un signal autre que
		# le nôtre, puisque sleep n'est pas terminé
		kill -TERM $pidsleep >/dev/null 2>/dev/null
		# note : après l'avoir terminé, on ne peut pas
		# faire un wait car sur certaines plateformes,
		exitcmd=130		# valeur arbitraire 130 (> 127)
	    else
		# la commande a été interrompue par notre signal et
		# notre sleep est terminé
		wait $pidsleep
		exitcmd=124		# cf man timeout sur Linux
	    fi
	fi
	return $exitcmd
    }
fi

# La commande "timeout" n'est pas POSIX, mais on fait comme si
# $1 = délai max en secondes
# $2 ... := commande et arguments
lancer_timeout ()
{
    [ $# -le 1 ] && fail "ERREUR SYNTAXE lancer_timeout"

    local delai="$1" ; shift

    local r
    timeout "$delai" "$@" > $TMP.out 2> $TMP.err
    r=$?
    [ $r = 124 ] && fail "Timeout de $delai sec dépassé pour : $*"
    return $r
}

# Teste si un processus existe
# $1 = pid
ps_existe ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE ps_existe"

    local pid="$1"
    local r

    if kill -0 $pid 2> /dev/null
    then r=0
    else r=1
    fi
    return $r
}

# Lancer valgrind avec toutes les options
tester_valgrind ()
{
    local r
    valgrind \
	--leak-check=full \
	--errors-for-leak-kinds=all \
	--show-leak-kinds=all \
	--error-exitcode=100 \
	--log-file=$TMP.valgrind \
	"$@" > $TMP.out 2> $TMP.err
    r=$?
    [ $r = 100 ] && fail "pb mémoire (cf $TMP.valgrind)"
    [ $r != 0 ]  && fail "erreur programme (code=$r) avec valgrind (cf $TMP.*)"
    return $r
}

##############################################################################
# Fonctions spécialisées pour les exercices Zorglub33

# Chercher un exécutable z33-cli quelque part dans les commandes ou
# dans le répertoire courant ou les répertoires parents
# $1 = contenu de la variable Z33 (nom de l'exécutable ou chemin)
z33_find ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE z33_find"
    local z33="$1"

    local exe dir

    if echo "$z33" | grep -q /
    then
	# il y a un "/" dans la variable Z33 : on essaye donc de trouver
	# ce chemin tel quel
	exe="$z33"
	if [ ! -x "$exe" ]
	then fail "Exécutable '$exe' non trouvé"
	fi
    else
	# pas de / dans la variable Z33 : ce doit donc être le nom d'une
	# commande, ou alors le nom d'un fichier 
	exe=$(command -v -p "$z33")
	if [ x"$exe" = x ]
	then
	    # ce n'est pas une commande : rechercher l'exécutable
	    # dans le répertoire courant ou les répertoires parents
	    dir="$PWD"
	    while [ "$dir" != "" ]
	    do
		exe="$dir/$z33"
		if [ -x "$exe" ]
		then break
		else dir=$(echo "$dir" | sed 's:/[^/]*$::')
		fi
	    done
	    if [ "$dir" = "" ]
	    then
		fail "Exécutable '$exe' non trouvé (PATH ou répertoires parents)"
	    fi
	fi
    fi
    Z33EXE=$exe
}

# Vérifier que la version de z33-cli est bien >= 0.6.0
# $1 : chemin de l'exécutable z33-cli
z33_check_version ()
{
    local v1 v2 v3
    local vmin="0 6 0" m1 m2 m3

    set $vmin
    m1=$1 ; m2=$2 ; m3=$3
    set $("$Z33EXE" -V | sed -e 's/.* //' -e 's/\./ /g')
    v1=$1 ; v2=$2 ; v3=$3
    if [ "$v1" -lt $m1 ]
    then fail "Version $Z33EXE = $v1.*.* insuffisante, min=$m1.$m2.$m3"
    elif [ "$v2" -lt $m2 ]
    then fail "Version $Z33EXE = $v1.$v2.* insuffisante, min=$m1.$m2.$m3"
    elif [ "$v3" -lt $m3 ]
    then fail "Version $Z33EXE = $v1.$v2.$v3 insuffisante, min=$m1.$m2.$m3"
    fi
}

# Chercher un label dans le fichier
# $1 = label à chercher
z33_chercher_label ()
{
    [ $# != 1 ] && fail "ERREUR SYNTAXE chercher_label"
    local label="$1"
    grep -q "^$label[ 	]*:" $PROG || fail "Label '$label' non trouvé"
}

# Chercher un reset dans le programme assembleur
z33_chercher_reset ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE chercher_reset"
    grep -q "^[ 	]*reset" $PROG || fail "Instruction 'reset' non trouvée"
}

# Lancer l'émulateur sur le point d'entrée
# $* = instructions (au moins une)
z33_run ()
{
    [ $# = 0 ] && fail "ERREUR SYNTAXE z33_run"

    local z33timeout=2			# secondes
    local r
    (
	cat "$PROG"
	echo
	echo "// ce qui suit est ajouté par le script de test"
        echo "// '_' : pour éviter des conflits avec les labels existants"
        echo "_test:"
	for i
	do
	    echo "$i" | sed 's/.*[^:]$/	&/'	# bien indenter les labels
	done
    ) > $TMP.s
    timeout $z33timeout $Z33EXE run $TMP.s "_test" > $TMP.out 2> $TMP.err
    r=$?
    [ $r = 124 ] && fail "Timeout de $z33timeout s dépassé"
    [ $r != 0 ] &&  fail "erreur de z33-cli => cf $TMP.s, $TMP.out et $TMP.err"
}

# Vérifier le résultat de l'exécution
# $1 = registre
# $2 = valeur
# $3 = msg d'erreur
z33_check ()
{
    [ $# != 3 ] && fail "ERREUR SYNTAXE z33_check"
    local reg="$1" val="$2" msg="$3"
    local v

    v=$(sed -n "/End of program/s/.*%$reg = \([^ ]*\) .*/\1/p" $TMP.out)
    [ x"$v" = x"$val" ] || fail "$msg, valeur trouvée = $v (attendue = $val) pour registre %$reg => regarder $TMP.s et $TMP.out"
}

##############################################################################
# Fonctions appelées systématiquement

# Chercher la commande "time" POSIX et la mettre dans la variable TIME
commande_time ()
{
    TIME=$(command -v -p time)
    if [ "$TIME" = "" ]
    then echo "Commande 'time' non trouvée" >&2  ; exit 1 ;
    fi
}

# Vérifier l'existence des programmes cités dans les variables PROG*
# et pour le cas des sources en assembleur (fichiers avec le suffixe ".s"),
# teste l'existence de l'émulateur Zorglub33 (z33-cli) dont le chemin
# doit figurer dans la variable Z33 ou alors dans PATH ou dans les répertoires
# répertoires parents
verifier_prog ()
{
    [ $# != 0 ] && fail "ERREUR SYNTAXE verifier_prog"
    local listevars v prog z33

    listevars=$(set | sed -n 's/^\(PROG[^=]*\)=.*/\1/p')
    z33=non
    for v in $listevars
    do
	prog=$(eval echo \$$v)
	case x"$prog" in
	    (*.s)
		if [ ! -f "$prog" ]
		then
		    echo "Fichier '$prog' (cité dans la variable $v) non trouvé" >&2
		    exit 1
		fi
		z33=oui
		;;
	    (*)
		if [ ! -x "$prog" ]
		then
		    echo "Exécutable '$prog' (cité dans la variable $v) non trouvé" >&2
		    exit 1
		fi
	esac
    done
    if [ $z33 = oui ]
    then
	z33_find "$Z33"			# trouve Z33EXE utilisé par la suite
	z33_check_version
    fi
}

##############################################################################
# Actions effectuées pour tous les tests, lors du chargement de ce fichier

#
# Analyser les options éventuelles
#

TESTS_TOUS=vrai			# faire tous les tests...
TESTS_A_FAIRE=""		# ... ou bien seulement certains
TESTS_VUS=""			# les tests qu'on a déjà vus (pour cohérence)
VERBOSE=faux			# affiche le détail d'un test
TERSE=faux			# affichage des résultats des tests
KEEP=rm				# nettoyer après le dernier test
DUREE=faux			# ne pas faire les tests, mais estimer la durée

while getopts "hvtkd" opt
do
    case "$opt" in
	(v)			# -v : verbose
	    VERBOSE=vrai
	    ;;
	(t)			# -t : terse
	    TERSE=vrai
	    ;;
	(k)			# -k : keep
	    KEEP=keep
	    ;;
	(d)
	    DUREE=vrai		# -d : durée maximum estimée
	    ;;
	(h|*)			# -h : help ou *: non reconnu
	    echo "usage: $0 [-h][-v][-t][-k][-d] [num...]" >&2
	    echo "exemple : $0 -v 2.1 2.3" >&2
	    exit 1
	    ;;
    esac
done

#
# Récupérer les numéros de tests demandés
#

shift $((OPTIND - 1))
for num
do
    if echo "$num" | grep -q "^[0-9][0-9]*\.[0-9][0-9]*$"
    then
	TESTS_TOUS=faux
	TESTS_A_FAIRE="$TESTS_A_FAIRE
$num"
    else
	echo "Numéro de test '$num' invalide" >&2
	exit 1
    fi
done

# Vérifier l'existence des programmes indiqués dans les variables "PROG*"
verifier_prog

# Chercher la commande "time"
commande_time

# Préparer l'action à réaliser automatiquement à la fin du script de test
trap "fin ; exit 0" EXIT
