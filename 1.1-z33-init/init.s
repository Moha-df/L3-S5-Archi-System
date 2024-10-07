//////////////////////////////////////////////////////////////////////////////

// programme "init"
.addr 3000
cible: 
        .word 0

init: 
        ld 123, %a
        ld 456, %b
        st %b, [cible]


        reset