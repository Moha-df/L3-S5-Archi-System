#include <errno.h>
#include <pthread.h>

/******************************************************************************
Sémaphores
******************************************************************************/

typedef struct monsem
{
    // à compléter
} monsem_t;

int monsem_init(monsem_t *s, int val);
int monsem_P(monsem_t *s);
int monsem_V(monsem_t *s);
