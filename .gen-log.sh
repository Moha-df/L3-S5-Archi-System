#!/bin/sh

#
# Ce script est destiné à être utilisé dans la CI de Gitlab
# afin de générer les pages de résultats de test.
#
# Prérequis : commandes timeout, bc, date
#

set -u
# set -e

PUB=public			# répertoire des artefacts Gitlab

CC=compil.txt			# log de compilation
TST=test.txt			# log général de chaque exo

# Extraire la date au début (pour être au plus proche de la date du commit)
DATE=$(TZ="Europe/Paris" date +"%d/%m/%Y à %H:%M")

rm -rf $PUB
mkdir -p $PUB

##############################################################################
# Liste des tests

# Génère sur stdout la liste des exercices dotés d'un script de test
liste_tests ()
{
    ls [0-9]*/test.sh | sed "s:/test.sh::"
}

##############################################################################
# Lancement des tests

# Lance les tests et renvoie sur la sortie standard une liste de la forme
# <score> <resultat> <resultat> ... <resultat>
# où :
#   <score> : le score global
#   <resultat> est :
#   	- CC : erreur de compilation
#   	- 100 : le programme passe tous les tests de l'exercice
#   	- n:numfail : passe n % des tests, num est le premier test qui échoue
# De plus, cette fonction laisse des fichiers dans le répertoire $PUBLIC :
#	- <num>/compil.txt : rapport de compilation
#	- <num>/test.txt : log du script de test
#	- <num>/tmp-<numfail>/ : résultat 
lancer_tests ()
{
    local res pubdir score num nbtst tstok pcentok numfail

    res=""
    score=0
    for num in $(liste_tests)
    do
	pubdir=$PUB/$num
	rm -rf $pubdir
	mkdir $pubdir
	if (cd $num ; make) > $pubdir/$CC 2>&1
	then
	    dur=$(cd $num ; sh ./test.sh -d)
	    timeout $dur sh -c "cd $num ; sh ./test.sh" > $pubdir/$TST 2>&1
	    r=$?
	    if [ $r = 0 ]
	    then
		# tout a bien fonctionné
		r=100
		score=$((score + 101))
	    else
		# aïe aïe aïe : un test a échoué
		nbtst=$(grep "^run_test " $num/test.sh | wc -l)
		tstok=$(grep "^Test .* OK$" $pubdir/$TST | wc -l)
		pcentok=$(( 100 * tstok / nbtst ))
		# test échoué = dernier test sans le OK final
		numfail=$(grep -v "Test.*OK$" $pubdir/$TST \
			    | sed -n 's/Test \([^ ]*\).*/\1/p')
		# petit complément esthétique en cas de timeout
		if [ $r = 124 ]
		then echo "TIMEOUT" >> $pubdir/$TST
		fi

		(
		    cd $num
		    dur=$(sh ./test.sh -d $numfail)
		    TMP=../$pubdir/tmp-$numfail \
			timeout $dur \
			    sh ./test.sh -v $numfail
		) > $pubdir/test-$numfail.txt 2>&1
		r="$pcentok:$numfail"
		score=$((score + pcentok + 1))
	    fi
	else
	    # pas de chance, ça ne compile pas
	    r=CC
	fi
	res="$res $r"
	chmod -R a+r $pubdir
    done

    # formatter le score avec 2 chiffres
    score=$(echo "scale=2 ; $score/100" | bc)
    score=$(printf "%0.2f" $score)

    echo $score $res
}


##############################################################################
# Génération HTML

# Génère le prologue de l'index général contenant le résultat des tests
prologue_html ()
{
    cat <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Résultat des tests</title>

    <style>
	body {
	    font-family: Arial, sans-serif;
	    background-color: #f4f4f4;
	    margin: 20px;
	}

	.item {
	    display: flex;
	    align-items: center;
	    margin-bottom: 20px;
	}

	.label {
	    font-weight: bold;
	    margin-right: 10px;
	    min-width: 250px;
	}

	.barre {
	    width: 100%;
	    height: 25px;
	    display: flex;
	    background-color: #e0e0e0;
	    border-radius: 5px;
	    overflow: hidden;
	}

	.gauche {
	    background-color: #4caf50;
	    height: 100%;
	    display: flex;
	    align-items: center;
	    justify-content: center;
	}
	.gauche a {
	    color: white;
	    text-decoration: none;
	    font-size: 14px;
	    font-weight: bold;
	}
	.gauche:hover a {
	    text-decoration: underline;
	}

	.droite {
	    background-color: #c30000;
	    height: 100%;
	    display: flex;
	    align-items: center;
	    justify-content: center;
	}

	.droite a {
	    color: white;
	    text-decoration: none;
	    font-size: 14px;
	    font-weight: bold;
	}

	.droite:hover a {
	    text-decoration: underline;
	}
    </style>
</head>
<body>
<h1>Résultat des tests : score = %SCORE% le %DATE%</h1>
EOF
}

# Génère l'épilogue de l'index général contenant le résultat des tests
epilogue_html ()
{
    cat <<'EOF'
</body>
</html>
EOF
}

# Génère l'index général avec les indicateurs
# $1 = score calculé lors du lancement des tests
# $2 ... $n = les résultats de chaque test
generer_index_general ()
{
    local score=$1
    shift
    local num res

    prologue_html | sed -e "s|%SCORE%|$score|" -e "s|%DATE%|$DATE|"

    for num in $(liste_tests)
    do
	echo "<div class=\"item\">"
	echo "<span class=\"label\">$num</span>"

	res=$1
	shift

	echo "<div class=\"barre\">"
	case "$res" in
	    (CC)
		echo "<div class=\"droite\" style=\"width: 100%; background-color: grey;\">"
		echo "<a href=\"$num/$CC\">Rapport de compilation</a>"
		echo "</div>"
		;;
	    (100)
		echo "<div class=\"gauche\" style=\"width: 100%;\">"
		echo "<a href=\"$num/$TST\">Log</a>"
		echo "</div>"
		;;
	    (*)
		pcentok=$(echo "$res" | cut -d: -f1)
		pcentfail=$((100 - pcentok))
		numfail=$(echo "$res" | cut -d: -f2)
		echo "<div class=\"gauche\" style=\"width: $pcentok%;\">"
		echo "<a href=\"$num/$TST\">Log</a>"
		echo "</div>"
		echo "<div class=\"droite\" style=\"width: $pcentfail%;\">"
		echo "<a href=\"$num/\">Log</a>"
		echo "</div>"

		;;
	esac
	echo "</div>"
	echo "</div>"
    done
    epilogue_html
}

# Génère un fichier HTML qui liste le contenu d'un répertoire
# $1 = numéro du test
# $2 ... = fichiers du répertoire
generer_page_contenu ()
{
    local num="$1"
    shift

    echo "<!DOCTYPE html>"
    echo "<html lang=\"fr\"><head>"
    echo "<meta charset=\"UTF-8\">"
    echo "<title>Fichiers du test $num</title>"
    echo "</head><body>"
    echo "<h1>Fichiers du test $num</h1>"
    echo "<ul>"
    for f
    do
	echo "<p><a href=\"$f\">$f</a></p>"
    done
    echo "</ul>"
    echo "</body></html>"
}

# Génère, pour chaque exo, une page listant les fichiers de log de l'exo
generer_logs ()
{
    local num l
    for num in $(liste_tests)
    do
	# On passe par un fichier dans /tmp pour ne pas modifier
	# la liste des fichiers dans $PUB/$num
	l=$(cd $PUB/$num ; find * -type f -print | sort)
	generer_page_contenu $num $l > $PUB/$num/index.html
    done
}

##############################################################################
# Programme principal

# Lancer tous les tests et placer les résultats individuels dans "res"
res=$(lancer_tests)

# Générer la page affichant toutes les belles barres vertes
generer_index_general $res > $PUB/index.html

# Générer les logs de chaque exo individuel
generer_logs

exit 0
