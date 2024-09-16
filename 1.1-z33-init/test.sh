#!/bin/sh

PROG=${PROG:=init.s}		# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "label 'init' demandé dans l'énoncé" && {
    z33_chercher_label "init"
}

run_test 1.2 "label 'cible' demandé dans l'énoncé" && {
    z33_chercher_label "cible"
}

# Il doit y avoir un reset (pour que le programme s'arrête)
run_test 1.3 "au moins un 'reset'" && {
    z33_chercher_reset
}

##############################################################################
# Tentative d'exécution de "init" pour voir s'il se termine

run2 ()
{
    z33_run "jmp init"
}

run_test 2.1 "exécution 'init'" && {
    run2
}

run_test 2.2 "test valeur 123 dans A" && {
    run2
    z33_check a 123 "valeur incorrecte dans A"
}

run_test 2.3 "pas d'utilisation de la pile" && {
    run2
    z33_check sp 10000 "SP modifié"
}

##############################################################################
# Test plus élaboré pour vérifier la valeur à l'adresse "cible"

run3 ()
{
    # on remplace le reset par un "rtn" pour pouvoir revenir après 'init'
    sed 's/reset/rtn/' $PROG > $TMP.rtn.s
    PROG=$TMP.rtn.s z33_run "call init" "ld [3000],%b" "reset"
}

run_test 3.1 "exécution 'init' comme un sous-programme" && {
    run3
}

run_test 3.2 "valeur lue depuis 3000" && {
    run3
    z33_check b 456 "valeur à l'adresse 3000 != 456"
}
