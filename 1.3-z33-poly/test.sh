#!/bin/sh

PROG=${PROG:=poly.s}		# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "labels demandés dans l'énoncé" && {
    z33_chercher_label "poly"
    z33_chercher_label "main_poly"
}

# Il doit y avoir un reset pour chaque main_* (pour que les prog. s'arrêtent)
# On se contente de z33_run la présence d'un seul reset pour simplifier
run_test 1.2 "au moins un 'reset'" && {
    z33_chercher_reset
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.3 "test 'main_poly'" && {
    z33_run "jmp main_poly"
}

##############################################################################
# Test 1

run1 ()
{
    z33_run "ld 8000,%sp" "ld 4567,%b" \
    	"push -5" "push _testpoly" "call poly" "reset" \
    	"_testpoly:" ".word 2" ".word -3" ".word -7"
}

run_test 2.1 "test 'poly' 1" && {
    run1
}

run_test 2.2 "test 'poly' 1 - retour dans A" && {
    run1
    z33_check a 58   "calcul incorrect dans A"
}

run_test 2.3 "test 'poly' 1 - B restauré" && {
    run1
    z33_check b 4567 "registre B non restauré"
}

run_test 2.4 "test 'poly' 1 - SP restauré" && {
    run1
    z33_check sp 7998 "registre SP non restauré"
}

##############################################################################
# Test 2

run2 ()
{
    z33_run "ld 3456,%sp" "ld 789,%b" \
    	"push 2" "push _testpoly" "call poly" "reset" \
    	"_testpoly:" ".word 2" ".word -18" ".word 5"
}

run_test 3.1 "test 'poly' 2" && {
    run2
}

run_test 3.2 "test 'poly' 2 - retour dans A" && {
    run2
    z33_check a -23  "calcul incorrect dans A"
}

run_test 3.3 "test 'poly' 2 - B restauré" && {
    run2
    z33_check b 789  "calcul incorrect dans A"
}

run_test 3.4 "test 'poly' 2 - SP restauré" && {
    run2
    z33_check sp 3454 "registre SP non restauré"
}
