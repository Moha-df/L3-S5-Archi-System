//////////////////////////////////////////////////////////////////////////////


poly:
// sp   : le bien qu'on va push
// sp+1 : le truc de retour (osef)
// sp+2 : tab[0]
// sp+3 : x
        push %b
        ld [%sp+2], %a
        ld [%a], %a
        ld [%sp+3], %b
        mul %b, %b
        mul %b, %a
        push %a
        ld [%sp+4], %b
        ld [%sp+3], %a
        ld [%a+1], %a
        mul %b, %a
        ld [%sp], %b
        add %b, %a
        ld [%sp+3], %b
        ld [%b+2], %b
        add %b, %a
        add 1, %sp
        pop %b
        rtn

        
#define x -5

main_poly:
        push x
        push tab
        call poly
        reset

tab:
        // tab_0
        .word 2
        // tab_1
        .word -3
        // tab_2
        .word -7

