include ../Makefile.inc

EXE ::= ranger sortir

all:: $(EXE)

ranger:	ranger.c bibli.h
sortir: sortir.c bibli.h

# Pour le nettoyage, on ajoute une règle pour supprimer les fichiers
# .o créés "à la main" par les règles ci-dessus
clean::
	rm -f *.o
