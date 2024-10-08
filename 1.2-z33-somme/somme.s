//////////////////////////////////////////////////////////////////////////////

// programme "somme" placé à l'adresse 2000
.addr 2000
somme:
        cmp 0, %b
        jge endSomme 
        push %b
        ld [%a], %b
        push %a
        add 1, %a
        ld [%a], %a
        add %a, %b
        pop %a
        add 1, %a
        st %b, [%a]
        pop %b
        sub 1, %b
        jmp somme
endSomme:
        ld [%a], %a
        rtn
        

main_somme:
        push %b
        ld 3, %b
        ld tab, %a
        call somme
        pop %b
        reset

tab:
        // tab_0
        .word 1
        // tab_1
        .word 2
        // tab_2
        .word 3
