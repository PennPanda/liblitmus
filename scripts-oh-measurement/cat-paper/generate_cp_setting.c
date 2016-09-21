#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

uint32_t get_continuous_cps(int num_cps)
{
    uint32_t cps;
    int i;

    cps = 0;
    for ( i = 0; i < num_cps; i++ )
    {
        cps |= ( 1UL << i );
    }

    return cps;
}

int main(int argc, char* argv[])
{
    int num_cps;
    uint32_t cps;

    if ( argc < 2 )
    {
        fprintf(stderr, "[Usage] ./program num_cps\n");
        exit(1);
    }

    num_cps = (int) atoi(argv[1]);
    if ( num_cps < 2 || num_cps > 20 )
    {
        fprintf(stderr, "num_cps = %d, must be [2,20]\n", num_cps);
        exit(1);
    }

    cps = get_continuous_cps(num_cps);

    printf("0x%"PRIx32"\n", cps);
}
