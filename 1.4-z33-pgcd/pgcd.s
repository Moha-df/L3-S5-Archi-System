//////////////////////////////////////////////////////////////////////////////

pgcd:
        push %b
        ld [%sp+2], %a
        ld [%sp+3], %b
loop_pgcd:
        cmp 0, %b
        jge end_pgcd
        sub 1, %sp
        st %b, [%sp]
        sub 1, %sp
        st %a, [%sp]
        div %b, %a
        mul %b, %a
        ld [%sp], %b
        add 1, %sp
        sub %a, %b
        ld [%sp], %a
        add 1, %sp
        jmp loop_pgcd

end_pgcd:
        pop %b
        rtn

main_pgcd:
        push %a
        push %b
        ld 24, %a
        ld 18, %b
        call pgcd
        pop %b
        reset

blopblop:
	ld 8000,%sp
	ld 4567,%b
	push 21
	push 15
	call pgcd
	reset