#!/bin/sh

PROG=${PROG:=calcul.s}		# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "labels demandés dans l'énoncé" && {
    z33_chercher_label "calcul"
    z33_chercher_label "main_calcul"
}

# Il doit y avoir un reset pour chaque main_* (pour que les prog. s'arrêtent)
# On se contente de z33_run la présence d'un seul reset pour simplifier
run_test 1.2 "au moins un 'reset'" && {
    z33_chercher_reset
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.3 "test 'main_calcul'" && {
    z33_run "jmp main_calcul"
}

##############################################################################
# Test 2

run2 ()
{
    z33_run "ld 8000,%sp" "ld 4567,%b" \
    	"push _testtab" "call calcul" "reset" \
    	"_testtab:" ".word 30" ".word 21" ".word 0"
}

run_test 2.1 "test 'calcul' 1" && {
    run2
}

run_test 2.2 "test 'calcul' 1 - retour dans A" && {
    run2
    z33_check a 5    "calcul incorrect dans A"
}

run_test 2.3 "test 'calcul' 1 - B restauré" && {
    run2
    z33_check b 4567 "registre B non restauré"
}

run_test 2.4 "test 'calcul' 1 - SP restauré" && {
    run2
    z33_check sp 7999 "registre SP non restauré"
}

##############################################################################
# Test 3

run3 ()
{
    z33_run "ld 2345,%sp" "ld 987,%b" \
    	"push _testtab" "call calcul" "reset" \
    	"_testtab:" ".word 30" ".word 0"
}

run_test 3.1 "test 'calcul' 2" && {
    run3
}

run_test 3.2 "test 'calcul' 2 - retour dans A" && {
    run3
    z33_check a 31    "calcul incorrect dans A"
}

run_test 3.3 "test 'calcul' 2 - B restauré" && {
    run3
    z33_check b 987   "registre B non restauré"
}

run_test 3.4 "test 'calcul' 2 - SP restauré" && {
    run3
    z33_check sp 2344 "registre SP non restauré"
}

##############################################################################
# Test 4

run4 ()
{
    z33_run "ld 7654,%sp" "ld 1789,%b" \
    	"push _testtab" "call calcul" "reset" \
    	"_testtab:" ".word 130" ".word 120" ".word 110" ".word 0"
}

run_test 4.1 "test 'calcul' 3" && {
    run4
}

run_test 4.2 "test 'calcul' 3 - retour dans A" && {
    run4
    z33_check a 13    "calcul incorrect dans A"
}

run_test 4.3 "test 'calcul' 3 - B restauré" && {
    run4
    z33_check b 1789  "registre B non restauré"
}

run_test 4.4 "test 'calcul' 3 - SP restauré" && {
    run4
    z33_check sp 7653 "registre SP non restauré"
}
