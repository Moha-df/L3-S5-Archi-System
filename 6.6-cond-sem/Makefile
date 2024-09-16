include ../Makefile.inc

CFLAGS += -pthread
LDLIBS += -lpthread

EXE := ex3th cat2th

ex3th: ex3th.o monsem.o
cat2th: cat2th.o monsem.o

# règle pour éviter de reconstruire monsem (on se limite à monsem.o
# qui est passé à l'édition de liens de ex3th et cat2th)
monsem: ;

clean::
	rm -f *.o
