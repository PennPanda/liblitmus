#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sched.h>

#include <sys/syscall.h>

#include "litmus.h"
#include "common.h"

//#define DEBUG   1

#define MHZ     (2299.871)
#define HZ      (MHZ * 1000 * 1000)

typedef enum
{
    IPI,
    LOCK
} type_t;

void help_usage()
{
    fprintf(stderr, "[usage] ipi/lock s_cpu_id cos_id cos_val times is_print\n");
    exit(1);
}

void print_latency(cycles_t *latency, int times)
{
    int i;

    //printf("iter\tcycles\tus\n");
    for ( i = 0; i < times; i++ )
    {
        printf("%d\t%lld\t%.3f\n", i, (unsigned long long) latency[i], latency[i] * 1.0 / MHZ);
    }
}

void check_cpu_affinity()
{
    cpu_set_t cpuset;
    int i;

    sched_getaffinity(0, sizeof(cpuset), &cpuset);
    printf("Run on cpus: ");
    for ( i = 0; i < CPU_SETSIZE; i++ )
    {
        if ( CPU_ISSET(i, &cpuset) )
            printf("%d ", i);
    }
    printf("\n");
    return;
}

/**
 * Param 1: ipi or lock
 * Param 2: s_cpu_id: CPU id to issue the request
 * Param 3: cos_id: COS register to modify
 * Param 4: val: val to write to the COS register
 * Param 5: times: Number of times of the request
 */
int main (int argc, char* argv[])
{
    type_t type;
    int s_cpu_id, times;
    uint32_t cos_id, cos_val;
    cycles_t start, finish;
    int is_print = 0;
    int ret;
    int i;
    cycles_t* latency;
    int (*set_cos) (uint32_t cos_id, uint32_t val, cycles_t *start, cycles_t *end);
    cpu_set_t cpuset;
    struct sched_param sched_param;

    ret = 0;

    if ( argc < 7 )
        help_usage();

    if ( !strcmp("ipi", argv[1]) )
    {
        type = IPI;
        set_cos = set_cos_ipi;
    }
    else if ( !strcmp("lock", argv[1]) )
    {
        set_cos = set_cos_lock;
        type = LOCK;
    }
    else
        help_usage();

    s_cpu_id = atoi(argv[2]);
    cos_id = atoi(argv[3]);
    cos_val = strtol(argv[4], NULL, 16);
    times = atoi(argv[5]);
    is_print = atoi(argv[6]);

#ifdef DEBUG
    printf("Type:%d s_cpu_id:%d cos_id:%d cos_val:%x times:%d\n",
            type, s_cpu_id, cos_id, cos_val, times);
#endif

    if ( cos_id < 0 || cos_id >= 4 )
    {
        fprintf(stderr, "cos_id (%d) must in range [0, 4]\n", cos_id);
        help_usage();
    }

    if ( times <= 0 )
    {
        fprintf(stderr, "number of requests (times:%d) must be > 0\n", times);
        help_usage();
    }

    /* store latency value */
    latency = (cycles_t *) malloc(sizeof(cycles_t) * times);
    if ( latency == NULL )
    {
        fprintf(stderr, "alloc for latency array fails\n");
        return 2;
    }

    memset(latency, 0, sizeof(latency));
    /* set cpu affinity */
    CPU_ZERO(&cpuset);
    CPU_SET(s_cpu_id, &cpuset);
    if ( sched_setaffinity(0, sizeof(cpuset), &cpuset) )
    {
        fprintf(stderr, "setaffinity fails. exit\n");
        return 3;
    }

    /* set sched to SCHED_FIFO and highest priority */
    memset(&sched_param, 0, sizeof(struct sched_param));
    sched_param.sched_priority = 99; /* highest priority in FIFO */
    if ( sched_setscheduler(0, SCHED_FIFO, &sched_param) )
    {
        fprintf(stderr, "setscheduler fails. exit\n");
        return 4;
    }
    
    for ( i = 0; i < times; i++ )
    {
#ifdef DEBUG
        check_cpu_affinity();
#endif
        ret = set_cos(cos_id, cos_val, &start, &finish);
        if ( ret )
        {
            fprintf(stderr, "set_cos(type:%d, iter=%d) fails ret=%d\n",
                    type, i, ret);
        }
        latency[i] = finish - start;
#ifdef DEBUG
        // if ( latency[i] <= 0 )
            printf("start: %lld finish: %lld\n", (unsigned long long) start, (unsigned long long) finish);
#endif
    }

    if ( is_print )
        print_latency(latency, times);

    return ret;
}
