include ../Makefile.inc
	
CFLAGS += -pthread

# question 1 : ctypes-unique (un unique mutex pour les accès)
# question 2 : ctypes-global (4 mutex distincts pour les accès)
# question 3 : ctypes-local (4 compteurs locaux, ajout en une seule fois)

EXE := ctypes-unique ctypes-global ctypes-local

# générer les programmes supplémentaires
all:: $(EXE)

ctypes-unique: ctypes.c
	$(CC) $(CFLAGS) -DUNIQUE $< -o $@

ctypes-global: ctypes.c
	$(CC) $(CFLAGS) -DGLOBAL $< -o $@

ctypes-local: ctypes.c
	$(CC) $(CFLAGS) -DLOCAL $< -o $@

# empêcher la compilation de l'exécutable "ctypes" (sans -D)
ctypes: ;
