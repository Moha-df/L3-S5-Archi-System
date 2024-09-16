include ../Makefile.inc

EXE += philo-interb table-interb
EXE += philo-term   table-term

all:: $(EXE)

philo-interb: philo.c
	$(CC) $(CFLAGS) -DINTERB $< -o $@

table-interb: table.c
	$(CC) $(CFLAGS) -DINTERB $< -o $@

philo-term: philo.c
	$(CC) $(CFLAGS) -DINTERB -DTERMINAISON $< -o $@

table-term: table.c
	$(CC) $(CFLAGS) -DINTERB -DTERMINAISON $< -o $@
