#!/bin/sh

PROG=${PROG:=coroutine.s}	# nom du fichier assembleur Zorglub33
Z33=${Z33:=z33-cli}		# chemin de l'exécutable z33-cli
				# cf https://github.com/sandhose/z33-emulator

# lire les variables et fonctions communes
. ../test-inc.sh

##############################################################################
# Tests de forme

# Recherche des labels demandés dans l'énoncé
run_test 1.1 "labels demandés dans l'énoncé" && {
    z33_chercher_label "cr_init"
    z33_chercher_label "cr_create"
    z33_chercher_label "cr_id"
    z33_chercher_label "cr_count"
    z33_chercher_label "cr_yield"
    z33_chercher_label "cr_exit"
    z33_chercher_label "cr_sleep"
    z33_chercher_label "cr_wakeup"
}

# Il doit y avoir un reset pour chaque main_* (pour que les prog. s'arrêtent)
# On se contente de z33_run la présence d'un seul reset pour simplifier
run_test 1.2 "au moins un 'reset'" && {
    z33_chercher_reset
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.3 "arrêt 'main_simple'" && {
    z33_run "jmp main_simple"
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.4 "arrêt 'main_complexe'" && {
    z33_run "jmp main_complexe"
}

# Tentative d'exécution de "main_*" pour voir s'il se terminent
run_test 1.5 "arrêt 'main_attente'" && {
    z33_run "jmp main_attente"
}

##############################################################################
# Test 2

run2 ()
{
    z33_run "jmp main_simple"
}
run_test 2.1 "test 'main_simple'" && {
    run2
}

run_test 2.2 "test 'main_simple' - retour dans A" && {
    run2
    z33_check a 123 "A non restauré par yield ?"
}

run_test 2.3 "test 'main_simple' - canari modifié par cr_simple" && {
    run2
    z33_check b 456 "B invalide : cr_simple exécuté ?"
}

run_test 2.4 "test 'main_simple' - SP valide" && {
    run2
    z33_check sp 10000 "registre SP non restauré"
}

##############################################################################
# Test 3

# valeurs dans le fichier .s fourni
N1=2 ; N2=3 ; N3=5

run3 ()
{
    z33_run "jmp main_complexe"
}

run_test 3.1 "test 'main_complexe'" && {
    run3
}

run_test 3.2 "test 'main_complexe' - N1+N2+N3 dans A" && {
    run3
    n=$((N1+N2+N3))
    z33_check a $n "nb total de yield par coroutines 1-3 invalide (devrait être $n)"
}

run_test 3.3 "test 'main_complexe' - nb de yields de coroutine 0 dans B" && {
    run3
    m=$N1
    if [ $m -lt $N2 ]
    then m=$N2
    fi
    if [ $m -lt $N3 ]
    then m=$N3
    fi
    m=$((m+1))
    z33_check b $m "nb de yields de coroutine 0 dans B devrait être $m"
}

run_test 3.4 "test 'main_complexe' - SP restauré" && {
    run3
    z33_check sp 10000 "registre SP non restauré"
}

##############################################################################
# Test 4

run4 ()
{
    z33_run "jmp main_attente"
}

run_test 4.1 "test 'main_attente'" && {
    run4
}

run_test 4.2 "test 'main_attente' - nb coroutines actives dans A" && {
    run4
    z33_check a 3 "résultat de cr_count invalide"
}

run_test 4.3 "test 'main_attente' - cr_attente arrivé jusqu'à exit" && {
    run4
    z33_check b 456  "cr_attente pas arrivé jusqu'à la modification de mc_att"
}

run_test 4.4 "test 'main_attente' - SP restauré" && {
    run4
    z33_check sp 10000 "registre SP non restauré"
}
