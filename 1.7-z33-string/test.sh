#!/bin/sh

PROG=${PROG:=string.s}		# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "labels demandés dans l'énoncé" && {
    z33_chercher_label "strlen"
    z33_chercher_label "main_strlen"
    z33_chercher_label "strcmp"
    z33_chercher_label "main_strcmp"
}

# Il doit y avoir un reset pour chaque main_* (pour que les prog. s'arrêtent)
# On se contente de z33_run la présence d'un seul reset pour simplifier
run_test 1.2 "au moins un 'reset'" && {
    z33_chercher_reset
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.3 "test 'main_strlen'" && {
    z33_run "jmp main_strlen"
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.4 "test 'main_strcmp'" && {
    z33_run "jmp main_strcmp"
}

##############################################################################
# Test 2

run2 ()
{
    z33_run "ld 8000,%sp" "ld 4567,%b" \
    	"push _testchaine" "call strlen" "reset" \
    	"_testchaine:" ".string \"abc\""
}

run_test 2.1 "test 'strlen' abc" && {
    run2
}

run_test 2.2 "test 'strlen' - retour dans A" && {
    run2
    z33_check a 3   "calcul incorrect dans A"
}

run_test 2.3 "test 'strlen' - B restauré" && {
    run2
    z33_check b 4567 "registre B non restauré"
}

run_test 2.4 "test 'strlen' - SP restauré" && {
    run2
    z33_check sp 7999 "registre SP non restauré"
}

##############################################################################
# Test 3

run3 ()
{
    z33_run "ld 3456,%sp" "ld 789,%b" \
    	"push _testchaine" "call strlen" "reset" \
    	"_testchaine:" ".word 0"
}

run_test 3.1 "test 'strlen' chaîne vide" && {
    run3
}

run_test 3.2 "test 'strlen' - retour dans A" && {
    run3
    z33_check a 0  "calcul incorrect dans A"
}

run_test 3.3 "test 'strlen' - B restauré" && {
    run3
    z33_check b 789  "calcul incorrect dans A"
}

run_test 3.4 "test 'strlen' - SP restauré" && {
    run3
    z33_check sp 3455 "registre SP non restauré"
}

##############################################################################
# Test 4

run4 ()
{
    z33_run "ld 3456,%sp" "ld 789,%b" \
    	"push _teststr2" "push _teststr1" "call strcmp" "reset" \
    	"_teststr1: .string \"abc\"" "_teststr2: .string \"abc\""
}

run_test 4.1 "test 'strcmp' str1 == str2 (abc = abc)" && {
    run4
}

run_test 4.2 "test 'strcmp' - retour dans A" && {
    run4
    z33_check a 0  "calcul incorrect dans A"
}

run_test 4.3 "test 'strcmp' - B restauré" && {
    run4
    z33_check b 789  "calcul incorrect dans A"
}

run_test 4.4 "test 'strcmp' - SP restauré" && {
    run4
    z33_check sp 3454 "registre SP non restauré"
}

##############################################################################
# Test 5

run5 ()
{
    z33_run "ld 8000,%sp" "ld 4567,%b" \
    	"push _teststr2" "push _teststr1" "call strcmp" \
    	"// if (0 > a) { a = -1 ; }" \
    	"cmp 0,%a" "jle _testfin" "ld -1,%a" "_testfin:" \
    	"reset" \
    	"_teststr1:" ".string \"abc\"" \
    	"_teststr2:" ".string \"abx\""
}

run_test 5.1 "test 'strcmp' str1 < str2 (abc < abx)" && {
    run5
}

run_test 5.2 "test 'strcmp' - retour négatif dans A" && {
    run5
    z33_check a -1 "calcul incorrect dans A (cf modif A dans $TMP.s)"
}

run_test 5.3 "test 'strcmp' - B restauré" && {
    run5
    z33_check b 4567 "calcul incorrect dans B"
}

run_test 5.4 "test 'strcmp' - SP restauré" && {
    run5
    z33_check sp 7998 "registre SP non restauré"
}

##############################################################################
# Test 6

run6 ()
{
    z33_run "ld 3456,%sp" "ld 789,%b" \
    	"push _teststr2" "push _teststr1" "call strcmp" \
    	"// if (0 > a) { a = -1 ; }" \
    	"cmp 0,%a" "jle _testfin" "ld -1,%a" "_testfin:" \
    	"reset" \
    	"_teststr1:" ".string \"abc\"" \
    	"_teststr2:" ".string \"abcd\""
}

run_test 6.1 "test 'strcmp' str1 < str2 (abc < abcd)" && {
    run6
}

run_test 6.2 "test 'strcmp' - retour négatif dans A" && {
    run6
    z33_check a -1 "calcul incorrect dans A (cf modif A dans $TMP.s)"
}

run_test 6.3 "test 'strcmp' - B restauré" && {
    run6
    z33_check b 789  "calcul incorrect dans B"
}

run_test 6.4 "test 'strcmp' - SP restauré" && {
    run6
    z33_check sp 3454 "registre SP non restauré"
}

##############################################################################
# Test 7

run7 ()
{
    z33_run "ld 8000,%sp" "ld 4567,%b" \
    	"push _teststr2" "push _teststr1" "call strcmp" \
    	"// if (0 < a) { a = 1 ; }" \
    	"cmp 0,%a" "jge _testfin" "ld 1,%a" "_testfin:" \
    	"reset" \
    	"_teststr1:" ".string \"xyz\"" \
    	"_teststr2:" ".string \"xya\""
}

run_test 7.1 "test 'strcmp' str1 > str2 (xyz > xya)" && {
    run7
}

run_test 7.2 "test 'strcmp' - retour positif dans A" && {
    run7
    z33_check a 1 "calcul incorrect dans A (cf modif A dans $TMP.s)"
}

run_test 7.3 "test 'strcmp' - B restauré" && {
    run7
    z33_check b 4567 "calcul incorrect dans B"
}

run_test 7.4 "test 'strcmp' - SP restauré" && {
    run7
    z33_check sp 7998 "registre SP non restauré"
}

##############################################################################
# Test 8

run8 ()
{
    z33_run "ld 3456,%sp" "ld 789,%b" \
    	"push _teststr2" "push _teststr1" "call strcmp" \
    	"// if (0 < a) { a = 1 ; }" \
    	"cmp 0,%a" "jge _testfin" "ld 1,%a" "_testfin:" \
    	"reset" \
    	"_teststr1:" ".string \"xyzt\"" \
    	"_teststr2:" ".string \"xyz\""
}

run_test 8.1 "test 'strcmp' str1 > str2 (xyzt > xyz)" && {
    run8
}

run_test 8.2 "test 'strcmp' - retour positif dans A" && {
    run8
    z33_check a 1 "calcul incorrect dans A (cf modif A dans $TMP.s)"
}

run_test 8.3 "test 'strcmp' - B restauré" && {
    run8
    z33_check b 789  "calcul incorrect dans B"
}

run_test 8.4 "test 'strcmp' - SP restauré" && {
    run8
    z33_check sp 3454 "registre SP non restauré"
}
