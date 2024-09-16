include ../Makefile.inc
	
CFLAGS += -pthread

EXE += thrmutex

# générer le programme thrmutex en plus de thr
all:: $(EXE)

thrmutex: thr.c
	$(CC) $(CFLAGS) -DMUTEX $< -o $@
