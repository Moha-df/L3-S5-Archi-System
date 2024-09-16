#!/bin/sh

PROG=${PROG:=minmax.s}		# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh


##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "labels demandés dans l'énoncé" && {
    z33_chercher_label "minmax"
    z33_chercher_label "main_minmax"
}

# Il doit y avoir un reset pour chaque main_* (pour que les prog. s'arrêtent)
# On se contente de z33_run la présence d'un seul reset pour simplifier
run_test 1.2 "au moins un 'reset'" && {
    z33_chercher_reset
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.3 "test 'main_minmax'" && {
    z33_run "jmp main_minmax"
}

##############################################################################
# Test 2

run2 ()
{
    z33_run "ld 8000,%sp" "ld 4567,%b" \
    	"push _testmax" "push _testmin" "push _testtab" \
    	"call minmax" "reset" \
    	"_testtab:" ".word 7" ".word 2" ".word 8" ".word 10" ".word 0" \
    	"_testmin:" ".word 0" \
    	"_testmax:" ".word 0"
}

run_test 2.1 "test 'minmax' 1" && {
    run2
}

run_test 2.2 "test 'minmax' 1 - retour dans A" && {
    run2
    z33_check a 4    "calcul incorrect dans A"
}

run_test 2.3 "test 'minmax' 1 - B restauré" && {
    run2
    z33_check b 4567 "registre B non restauré"
}

run_test 2.4 "test 'minmax' 1 - SP restauré" && {
    run2
    z33_check sp 7997 "registre SP non restauré"
}

##############################################################################
# Test 3

run3 ()
{
    z33_run "ld 7654,%sp" \
    	"push _testmax" "push _testmin" "push _testtab" \
    	"call minmax" \
    	"ld [_testmin],%a" "ld [_testmax],%b" "reset" \
    	"_testmin:" ".word 0" \
    	"_testtab:" ".word 7" ".word 2" ".word 8" ".word 10" ".word 0" \
    	"_testmax:" ".word 0"
}

run_test 3.1 "test 'minmax' 2" && {
    run3
}

run_test 3.2 "test 'minmax' 2 - min dans A" && {
    run3
    z33_check a 2    "min incorrect dans A"
}

run_test 3.3 "test 'minmax' 2 - max dans B" && {
    run3
    z33_check b 10   "max incorrect dans B"
}

run_test 3.4 "test 'minmax' 2 - SP restauré" && {
    run3
    z33_check sp 7651 "registre SP non restauré"
}

##############################################################################
# Test 4

run4 ()
{
    z33_run "ld 8000,%sp" "ld 1234,%b" \
    	"push _testmax" "push _testmin" "push _testtab" \
    	"call minmax" "reset" \
    	"_testtab:" ".word 0" \
    	"_testmin:" ".word 0" \
    	"_testmax:" ".word 0"
}

run_test 4.1 "test 'minmax' 3" && {
    run4
}

run_test 4.2 "test 'minmax' 3 - retour dans A" && {
    run4
    z33_check a 0    "calcul incorrect dans A"
}

run_test 4.3 "test 'minmax' 3 - B restauré" && {
    run4
    z33_check b 1234 "registre B non restauré"
}

run_test 4.4 "test 'minmax' 3 - SP restauré" && {
    run4
    z33_check sp 7997 "registre SP non restauré"
}

##############################################################################
# Test 5
# la boucle n'étant jamais parcourue, min et max restent à leur valeur initiale

run5 ()
{
    z33_run "ld 5678,%sp" \
    	"push _testmax" "push _testmin" "push _testtab" \
    	"call minmax" \
    	"ld [_testmin],%a" "ld [_testmax],%b" "reset" \
    	"_testtab:" ".word 0" \
    	"_testmin:" ".word 0" \
    	"_testmax:" ".word 0"
}

run_test 5.1 "test 'minmax' 4" && {
    run5
}

run_test 5.2 "test 'minmax' 4 - min dans A" && {
    run5
    z33_check a 10000 "min incorrect dans A"
}

run_test 5.3 "test 'minmax' 4 - max dans B" && {
    run5
    z33_check b 0     "max incorrect dans B"
}

run_test 5.4 "test 'minmax' 4 - SP restauré" && {
    run5
    z33_check sp 5675 "registre SP non restauré"
}

##############################################################################
# Test 6

run6 ()
{
    z33_run "ld 7612,%sp" "ld 987,%b" \
    	"push _testmax" "push _testmin" "push _testtab" \
    	"call minmax" "reset" \
    	"_testmax:" ".word 0" \
    	"_testtab:" ".word 2" ".word 8" ".word 9" ".word 18" ".word 0" \
    	"_testmin:" ".word 0"
}

run_test 6.1 "test 'minmax' 5" && {
    run6
    z33_run "ld 7612,%sp" "ld 987,%b" \
    	"push _testmax" "push _testmin" "push _testtab" \
    	"call minmax" "reset" \
    	"_testmax:" ".word 0" \
    	"_testtab:" ".word 2" ".word 8" ".word 9" ".word 18" ".word 0" \
    	"_testmin:" ".word 0"
}

run_test 6.2 "test 'minmax' 5 - retour dans A" && {
    run6
    z33_check a 4     "calcul incorrect dans A"
}

run_test 6.3 "test 'minmax' 5 - B restauré" && {
    run6
    z33_check b 987   "registre B non restauré"
}

run_test 6.4 "test 'minmax' 5 - SP restauré" && {
    run6
    z33_check sp 7609 "registre SP non restauré"
}
