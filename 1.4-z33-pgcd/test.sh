#!/bin/sh

PROG=${PROG:=pgcd.s}		# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "labels demandés dans l'énoncé" && {
    z33_chercher_label "pgcd"
    z33_chercher_label "main_pgcd"
}

# Il doit y avoir un reset pour chaque main_* (pour que les prog. s'arrêtent)
# On se contente de z33_run la présence d'un seul reset pour simplifier
run_test 1.2 "au moins un 'reset'" && {
    z33_chercher_reset
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.3 "test 'main_pgcd'" && {
    z33_run "jmp main_pgcd"
}

##############################################################################
# Test 2

run2 ()
{
    z33_run "ld 8000,%sp" "ld 4567,%b" \
    	"push 21" "push 15" "call pgcd" "reset"
}

run_test 2.1 "test 'pgcd' 1" && {
    run2
}

run_test 2.2 "test 'pgcd' 1 - retour dans A" && {
    run2
    z33_check a 3    "calcul incorrect dans A"
}

run_test 2.3 "test 'pgcd' 1 - B restauré" && {
    run2
    z33_check b 4567 "registre B non restauré"
}

run_test 2.4 "test 'pgcd' 1 - SP restauré" && {
    run2
    z33_check sp 7998 "registre SP non restauré"
}

##############################################################################
# Test 3

run3 ()
{
    z33_run "ld 3456,%sp" "ld 987,%b" \
    	"push 0" "push 30" "call pgcd" "reset"
}

run_test 3.1 "test 'pgcd' 2" && {
    run3
}

run_test 3.2 "test 'pgcd' 2 - retour dans A" && {
    run3
    z33_check a 30   "calcul incorrect dans A"
}

run_test 3.3 "test 'pgcd' 2 - B restauré" && {
    run3
    z33_check b 987  "registre B non restauré"
}

run_test 3.4 "test 'pgcd' 2 - SP restauré" && {
    run3
    z33_check sp 3454 "registre SP non restauré"
}

##############################################################################
# Test 4

run4 ()
{
    z33_run "ld 789,%b" "ld 7654,%sp" \
    	"push 21505" "push 18183" "call pgcd" "reset"
}

run_test 4.1 "test 'pgcd' 3" && {
    run4
}

run_test 4.2 "test 'pgcd' 3 - retour dans A" && {
    run4
    z33_check a 11   "calcul incorrect dans A"
}

run_test 4.3 "test 'pgcd' 3 - B restauré" && {
    run4
    z33_check b 789  "calcul incorrect dans A"
}

run_test 4.4 "test 'pgcd' 3 - SP restauré" && {
    run4
    z33_check sp 7652 "registre SP non restauré"
}
