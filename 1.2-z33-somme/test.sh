#!/bin/sh

PROG=${PROG:=somme.s}		# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "label demandé dans l'énoncé" && {
    z33_chercher_label "main_somme"
}

# Il doit y avoir un reset (pour que le programme s'arrête)
run_test 1.2 "au moins un 'reset'" && {
    z33_chercher_reset
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.3 "test 'main_somme'" && {
    z33_run "jmp main_somme"
}

##############################################################################
# Somme de 3 valeurs

run2 ()
{
    z33_run "ld _testtab,%a" "ld 3,%b" \
    	"jmp 2000" \
    	"_testtab:" ".word 2" ".word -3" ".word 10"
}

run_test 2.1 "somme 3 valeurs" && {
    run2
}

run_test 2.2 "retour dans A" && {
    run2
    z33_check a 9 "calcul incorrect dans A"
}

##############################################################################
# Somme de 5 valeurs

run3 ()
{
    z33_run "ld _testtab,%a" "ld 5,%b" \
    	"jmp 2000" \
    	"_testtab:" ".word 12" ".word 25" ".word 33" ".word 7" ".word 11"
}

run_test 3.1 "somme 5 valeurs" && {
    run3
}

run_test 3.2 "retour dans A" && {
    run3
    z33_check a 88 "calcul incorrect dans A"
}

##############################################################################
# Cas particulier

run4 ()
{
    z33_run "ld _testtab,%a" "ld 0,%b" \
    	"jmp 2000" \
    	"_testtab:"
}

run_test 4.1 "somme 0 valeur" && {
    run4
}

run_test 4.2 "retour dans A (attendu 0)" && {
    run4
    z33_check a 0 "calcul incorrect dans A"
}
