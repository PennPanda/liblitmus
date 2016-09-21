/**
 * get rt_param of a specified pid
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "litmus.h"

#define ARRAYSIZE(arr)      (sizeof(arr)/sizeof(arr[0]))
#define CACHE_LINE_SIZE     64

#if defined(__i386__)
static __inline__ unsigned long long rdtsc(void)
{
  unsigned long long int x;
     __asm__ volatile (".byte 0x0f, 0x31" : "=A" (x));
     return x;
}
#elif defined(__x86_64__)
static __inline__ unsigned long long rdtsc(void)
{
  unsigned hi, lo; 
  __asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
  return ( (unsigned long long)lo)|( ((unsigned long long)hi)<<32 );
}
#endif

#define GHZ     2.3
#define MHZ     2300

int generate_valid_cps(uint32_t * cps)
{
    int value, num_ones, i;

    value = 0;
    num_ones = 2 + rand() % 19;

    for ( i = 0; i < num_ones; i++ )
    {
        int which_bit;
        which_bit = rand() % 20;
        if ( value & (1 << which_bit) )
        {
            i--;
            continue;
        } else
        {
            value |= (1 << which_bit);
        }
    }
    *cps = value;

    return 0;
}

void print_latencies(long *latency, int size)
{
    int i = 0;
    printf("index\tcycles\t\tns\tus\n");
    for ( i = 0; i < size; i++ )
    {
        printf("%d\t%ld\t%.2f\t%ld\n", i, latency[i], latency[i] * 1.0 / GHZ, latency[i] / MHZ);
    }
}

int main(int argc, char** argv)
{
	struct rt_cache param;
	pid_t pid;
    uint32_t new_cps;
    int iterations;
    long *latency = NULL;
    long start, finish;
    int i;

	if ( argc < 3 )
	{
		printf("[usage] set_task_rt_cps pid iterations\n");
		exit(1);
	}
	pid = atoi(argv[1]);
	if (pid == 0)
	{
		pid = gettid();
	}
    iterations = atoi(argv[2]);
    if ( iterations < 0 )
    {
        fprintf(stderr, "iterations: %d is invalid\n", iterations);
        exit(1);
    }
    latency = malloc( iterations * sizeof(long) );
    if ( !latency )
    {
        fprintf(stderr, "malloc for latency fails. latency is NULL.\n");
        exit(1);
    }

    printf("set_rt_task_cps:pid=%d for %d times now\n", pid, iterations);

    for ( i = 0; i < iterations; i++ )
    {
        generate_valid_cps(&new_cps);
        param.set_of_cps = new_cps;
        param.flush = 0;
        start = rdtsc();
        if (set_rt_task_cps(pid, &param))
        {
            printf("set_rt_task_cps fails\n");
            exit(2);
        }
        finish = rdtsc();
        latency[i] = finish - start;
    }

	print_latencies(latency, iterations);

	return 0;
}
