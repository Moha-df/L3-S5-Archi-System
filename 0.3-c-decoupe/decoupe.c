#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>

noreturn void usage(const char *argv0)
{
    fprintf(stderr, "usage: %s val pos\n", argv0);
    exit(1);
}

int main(int argc, char *argv[])
{
    uint32_t val;
    int pos;

    if (argc != 3)
        usage(argv[0]);

    exit(0);
}
