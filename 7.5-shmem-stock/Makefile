include ../Makefile.inc

EXE ::= ctrl liste aref rref ajout retrait

all:: $(EXE)

#
# Comme la cible "all" est définie dans Makefile.inc avec la compilation
# de chaque .c en un programme autonome, on crée de fausses règles pour
# désactiver la création des programmes ajoutretrait, arref et stock.
#
ajoutretrait:	ajoutretrait.c
	@true
arref:	arref.c
	@true
stock:	stock.o
	@true

#
# Comme ajout et retrait viennent du même source ajoutretrait.c
# (idem pour aref et rref qui viennent de arref.c), on utilise la
# compilation conditionnelle pour distinguer les 2 programmes.
#
ajout.o: ajoutretrait.c
	$(CC) $(CFLAGS) -DAJOUT -o $@ -c $<
retrait.o: ajoutretrait.c
	$(CC) $(CFLAGS) -DRETRAIT -o $@ -c $<

aref.o: arref.c
	$(CC) $(CFLAGS) -DAJOUT -o $@ -c $<
rref.o: arref.c
	$(CC) $(CFLAGS) -DRETRAIT -o $@ -c $<

# Inclure le fichier stock.o dans chacun des programmes
$(EXE): stock.o

# Pour le nettoyage, on ajoute une règle pour supprimer les fichiers
# .o créés "à la main" par les règles ci-dessus
clean::
	rm -f *.o
