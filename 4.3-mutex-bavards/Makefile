include ../Makefile.inc
	
CFLAGS += -pthread

EXE += bavards-ok

# générer les programmes supplémentaires
all:: $(EXE)

bavards-ok: bavards.c
	$(CC) $(CFLAGS) -DOK $< -o $@
