#include <sys/time.h>
#include <sys/mman.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <assert.h>
#include <limits.h>
#include <fcntl.h>

#include <sched.h>

#include "litmus.h"
#include "common.h"

#define NUM_CACHE_PARTITIONS 	8

void check_cp_setting(struct timespec start);

static void usage(char *error) {
	fprintf(stderr, "Error: %s\n", error);
	fprintf(stderr,
		"Usage:\n"
		"	ca_spin [COMMON-OPTS] WCET PERIOD DURATION\n"
		"\n"
		"COMMON-OPTS = [-w] [-r 0/1] \n"
		"              [-p PARTITION/CLUSTER ] [-c CLASS]\n"
		"	       [-C num of cache partitions]"
		"\n"
		"WCET and PERIOD are milliseconds, DURATION is seconds.\n");
	exit(EXIT_FAILURE);
}

static char* progname;
static pid_t my_pid;
static int job_no;
static int NUM_CP;
int use_cpu_loop = 1;
int flag_printf = 0;
//////////////////////////////////////////

#define KB_IN_CACHE_PARTITION	64

#define CACHELINE_SIZE 32
#define INTS_IN_CACHELINE (CACHELINE_SIZE / sizeof(int))
#define CACHELINES_IN_1KB (1024 / sizeof(cacheline_t))
#define INTS_IN_1KB (1024 / sizeof(int))
#define INTS_IN_CACHELINE (CACHELINE_SIZE / sizeof(int))

static int loops = 10;

#define NPAD                7
struct cache_line {
    struct cache_line *next;
    long int pad[NPAD];
};
typedef struct cache_line cache_line_t;


struct cache_measurement {
    cache_line_t *head;
    cache_line_t *cache;
    long array_size;
    long num_busy_loop;
    long num_iterations;
};
typedef struct cache_measurement cache_measurement_t;

#define CACHE_LINE_SIZE     64
#define PAGE_OFFSET_MASK    0x0FFF
#define PAGE_SIZE  4096
#define NUM_ELEM_PER_PAGE (PAGE_SIZE / sizeof(cache_line_t))


int warm_cache ( cache_line_t *head )
{
    cache_line_t *cur = head;
    int i;
    long sum = 0;

    /* iterate along linked list */
    while ( cur->next != NULL )
    {
        for ( i = 0; i < NPAD; i++ )
            sum += cur->next->pad[i];
        cur = cur->next;
    }

    return 0;
}

int sanity_check_access_pattern ( cache_line_t *cache, long array_size, cache_line_t *head )
{
    long int i, j;
    cache_line_t *cur = head;
    long sum1 = 0, sum2 = 0;

    /* identify each element */
    for ( i = 0; i < array_size; i++ )
    {
        for ( j = 0; j < NPAD; j++ )
            cache[i].pad[j] = i;
        sum1 += i;
    }

    /* iterate along linked list */
    i = 0;
    while ( cur->next != NULL )
    {
        dbprintf("%ld ", cur->next->pad[0]);
        sum2 += cur->next->pad[0];
        cur = cur->next;
        i++;
    }

    dbprintf("\r\n");
    dbprintf("Total num of iterated elemet is %ld; sum of iteration is %ld\n", i, sum2);
    return 0;
}

cache_line_t * random_full_each_line_prepare(cache_line_t *cache, long array_size)
{
    /** 
     * Access partern to measure latency of reloading whole array
     * Access the element randomly in the whole array;
     * Random does not limit to a single page
     */
    int i;
    cache_line_t *head = (cache_line_t*) malloc( sizeof(cache_line_t) ); /* dummy head */
    cache_line_t *cur = head;
    int *index_array = (int *) malloc(array_size * sizeof(int));
    int index;
    int tmp;

    if ( head == NULL )
    {
        fprintf(stderr, "head is NULL\n");
        exit(ENOMEM);
    }

    srand(0); /* In order to repeat the experiment */
    /* init index array to be 0 - array_size */
    for ( i = 0; i < array_size; i++ )
        index_array[i] = i;

    /* shuffle the access sequence in page */
    for ( i = 0; i < array_size; i++ )
    {
        tmp = rand() % array_size; /* rand return 0 to RAND_MAX */
        assert( tmp < array_size );
        swap(index_array, i, tmp); 
    }
    
    for ( i = 0; i < array_size; i++ )
    {
        index = index_array[i];
        if ( index >= array_size )
            continue;
        cur->next = &cache[index];
        cur = cur->next;
    }

    free( index_array );
    return head;
}

static inline void * adjust_to_page_align ( void *p )
{
    void *p_new = p;

    p_new = p + (0x1000L - ((long) p & PAGE_OFFSET_MASK)); /* allign to page */
//    printf("malloc %0lx\n", (long) p_new);
    return p_new;
}

long measure_each_line_access_pattern ( const cache_measurement_t *measurement )
{
    /** 
     * Access partern to measure latency of reloading whole l2 
     * first access all first payload by striding page to avoid prefetch
     * Then access the next payload
     */
    int j, k, index;
    cache_line_t *cur = measurement->head;
    long sum = 0;
    long start, finish;
    long tmp;

    assert( cur != NULL );
    
    for ( k = 0; k < measurement->num_iterations; k++ )
    {
        /* for each iteration of the whole array */
        sum = 0;
        cur = measurement->head;

        while( cur->next != NULL ) /* iterate all cache_line */
        {
            sum += cur->next->pad[0]; /* read */
            cur = cur->next;
        }

        /* wait for next period */
//        usleep(measurement->period);
        j = 0; /* cpu payload for cache interference */
        while ( j++ < measurement->num_busy_loop )
                tmp += j * j;
    }

    return sum;
}

cache_line_t *cache_origin; /* to free all alloc memory */
cache_line_t *cache; /* to load data each time to use it */
cache_measurement_t measurement;
int random_full_each_line_func( long array_space_B, long num_busy_loop, long num_loops)
{
    int ret;
    long sum;
    long cache_origin_size;
    long cache_size;
    cache_line_t *head;

    memset( (void *) &measurement, 0, sizeof(measurement) );
    /* input parse */
    measurement.num_busy_loop = num_busy_loop;
    measurement.num_iterations = num_loops;
    measurement.array_size = array_space_B / sizeof(cache_line_t);
    cache_origin_size = sizeof(cache_line_t) * measurement.array_size + PAGE_SIZE;
    cache_size = sizeof(cache_line_t) * measurement.array_size;

    dbprintf("num_busy_loop=%ld, num_iteration=%ld\n", 
            measurement.num_busy_loop, measurement.period, measurement.num_iterations);

    cache_origin = (cache_line_t *) malloc( cache_origin_size );
    cache = cache_origin;
    /* allign to page offset */
    cache = (cache_line_t *) adjust_to_page_align( (void *) cache );
    if ( cache == NULL )
    {
        fprintf(stderr, "alloc cache with size %ld fails\n", array_space_B);
        return -ENOMEM;
    }
    memset( (void *) cache, 0, cache_size);

    head = random_full_each_line_prepare( cache, measurement.array_size );
    assert( head != NULL );
    
    ret = sanity_check_access_pattern( cache, measurement.array_size, head );

    warm_cache( head );
    warm_cache ( head );

    measurement.cache = cache;
    measurement.head = head;
    //sum = measure_each_line_access_pattern( &measurement );

out:
    //if ( cache_origin != NULL )
    //    free( cache_origin );
    sleep_next_period();
    return ret;
}

#define UNCACHE_DEV "/dev/litmus/uncache"

int count_bits(uint16_t cp_mask)
{
	int i = 0;
	int count = 0;
	
	for (i = 0; i < 16; i++)
	{
		if (cp_mask & (1<<i))
			count++;
	}
	return count;
}

int cpu, cpu_prev = -1;
uint16_t cp_cur = -1, cp_prev = -1;
struct timespec last_time, cur_time;
double dur_tmp, dur_tmp2;
int invalid_cp_flag;
uint16_t cp_prev;
void check_cp_setting(struct timespec start)
{
	struct rt_job job_params;
	int ret;

	// read cpu
	cpu = sched_getcpu();
	ret = get_rt_job_param(my_pid, &job_params);
	if (ret)
		printf("get_rt_job_params fails, err=%d\n", ret);
	cp_cur = job_params.cache_partitions;
	if (cp_cur != cp_prev)
	{
		if (flag_printf == 1)
			printf("pid=%d job_no=%d cpu_prev=%d cpu_cur=%d cp_prev=0x%x cp_cur=0x%x dur_invalidt=%.3fus\n",
				my_pid, job_no, cpu_prev, cpu, cp_prev, cp_cur, dur_tmp);
		cp_prev = cp_cur;
	}
	if (count_bits(job_params.cache_partitions) != NUM_CP)
	{
		mark_event(my_pid, 1, 0);
		invalid_cp_flag = 1;
		clock_gettime(CLOCK_REALTIME, &cur_time);
		cp_prev = cp_cur;
		cpu_prev = cpu;
	}
	if (invalid_cp_flag == 1 && count_bits(job_params.cache_partitions) == NUM_CP)
	{
		mark_event(my_pid, 2, 0);
		invalid_cp_flag = 0;
		dur_tmp = (cur_time.tv_sec - start.tv_sec) * 1000000 
			+ (cur_time.tv_nsec - start.tv_nsec) * 1.0 / 1000;
		if (flag_printf == 1)
			printf("pid=%d job_no=%d cpu_prev=%d cpu_cur=%d cp_prev=0x%x cp_cur=0x%x dur_invalidt=%.3fus\n",
				my_pid, job_no, cpu_prev, cpu, cp_prev, cp_cur, dur_tmp);
	}
}
//////////////////////////////////////////
void die(char *x){ perror(x); exit(1); };
#define ONE_SEC 1000000000L
#define BS	1024
static int job(const cache_measurement_t *measurement, double program_end)
{
	if (wctime() > program_end)
		return 0;
	else {
		register unsigned int iter = 0;
        	struct timespec start, finish;

		invalid_cp_flag = 0;
                clock_gettime(CLOCK_REALTIME, &start);
 
		while(iter++ < loops) {
			check_cp_setting(start);
			/* each cp takes 100us if cache hit */
			if (use_cpu_loop)
				loop_cpu_once(100 * NUM_CP);
			measure_each_line_access_pattern (measurement);
		}

                clock_gettime(CLOCK_REALTIME, &finish);
		if (flag_printf == 1)
                	printf("[WCET] pid=%d job_no=%d %ld %ld %.3f\n",my_pid, job_no, finish.tv_sec - start.tv_sec, finish.tv_nsec - start.tv_nsec,
                    		(finish.tv_sec - start.tv_sec) * 1.0 * (ONE_SEC/1000) + (finish.tv_nsec - start.tv_nsec) * 1.0 / 1000);

		sleep_next_period();
		return 1;
	}
}

#define OPTSTR "p:c:C:weq:r:l:S:U:f:"
int main(int argc, char** argv)
{
	int ret;
	lt_t wcet;
	lt_t period;
	double wcet_ms, period_ms;
	unsigned int priority = LITMUS_LOWEST_PRIORITY;
	unsigned int num_cache_partitions = NUM_CACHE_PARTITIONS;
	int migrate = 0;
	int cluster = 0;
	int opt;
	int wait = 0;
	int want_enforcement = 0;
	double duration = 0, start = 0;
	task_class_t class = RT_CLASS_HARD;
	struct rt_task param, param_tmp;

	int wss = 0;
	int shuffle = 1;
	size_t arena_size;
	int size_kb = -1;
	job_no = 0;

	progname = argv[0];

	while ((opt = getopt(argc, argv, OPTSTR)) != -1) {
		switch (opt) {
		case 'w':
			wait = 1;
			break;
		case 'p':
			cluster = atoi(optarg);
			migrate = 1;
			break;
		case 'q':
			priority = atoi(optarg);
			if (!litmus_is_valid_fixed_prio(priority))
				usage("Invalid priority.");
			break;
		case 'c':
			class = str2class(optarg);
			if (class == -1)
				usage("Unknown task class.");
			break;
		case 'C':
			num_cache_partitions = atoi(optarg);
			if ( num_cache_partitions < 0 || num_cache_partitions > MAX_CACHE_PARTITIONS)
				usage("Invalid partition number. Must be [0,16]");
			NUM_CP = num_cache_partitions;
			break;
		case 'S':
			size_kb = atoi(optarg);
			break;
		case 'U':
			use_cpu_loop = atoi(optarg);
			break;
		case 'f':
			flag_printf = atoi(optarg);
			break;
		case 'e':
			want_enforcement = 1;
			break;
		case 'r':
			shuffle = atoi(optarg);
			if(shuffle) {
				shuffle = 1;
			}
			break;
		case 'l':
			loops = atoi(optarg);
			break;
		case ':':
			usage("Argument missing.");
			break;
		case '?':
		default:
			usage("Bad argument.");
			break;
		}
	}

	//srand(getpid());
	srand(0);


	if (argc - optind < 3)
		usage("Arguments missing.");

	wcet_ms   = atof(argv[optind + 0]);
	period_ms = atof(argv[optind + 1]);

	wcet   = ms2ns(wcet_ms);
	period = ms2ns(period_ms);
	if (wcet <= 0)
		usage("The worst-case execution time must be a "
				"positive number.");
	if (period <= 0)
		usage("The period must be a positive number.");
	if (wcet > period) {
		usage("The worst-case execution time must not "
				"exceed the period.");
	}

	duration  = atof(argv[optind + 2]);

	if (migrate) {
		ret = be_migrate_to_cpu(cluster); //be_migrate_to_domain(cluster);
		if (ret < 0)
			bail_out("could not migrate to target partition or cluster.");
	}

	//set up wss based on num_cache_partitions
	if (size_kb == -1)
		wss = KB_IN_CACHE_PARTITION * (num_cache_partitions - 2);
	else
		wss = size_kb;
	printf("wss=%dKB\n", wss);
	arena_size = wss * 1024;

	init_rt_task_param(&param);
	param.exec_cost = wcet;
	param.period = period;
	param.priority = priority;
	param.cls = class;
	param.budget_policy = (want_enforcement) ?
			PRECISE_ENFORCEMENT : NO_ENFORCEMENT;
	if (migrate)
		param.cpu = cluster; //domain_to_first_cpu(cluster);

	param.num_cache_partitions = num_cache_partitions;

	ret = set_rt_task_param(gettid(), &param);
	if (ret < 0)
		bail_out("could not setup rt task params");

	ret = get_rt_task_param(gettid(), &param_tmp);
	if (ret < 0)
		bail_out("could not get rt task params");
	printf("MX: num_cache_partitions=%d\n", param_tmp.num_cache_partitions);

	init_litmus();

	printf("MX:before task_mode(LITMUS_RT_TASK)\n");
	ret = task_mode(LITMUS_RT_TASK);
	printf("MX:after task_mode(LITMUS_RT_TASK)\n");
	if (ret != 0)
		bail_out("could not become RT task");

	if (wait) {
		ret = wait_for_ts_release();
		if (ret != 0)
			bail_out("wait_for_ts_release()");
	}

	random_full_each_line_func(arena_size, 0, loops);
	//initialize(arena_size, shuffle);

	my_pid = getpid();
	start = wctime();

	while (job(wss, shuffle, wcet_ms * 0.001, start + duration))
	{
		job_no++;
	};

	ret = task_mode(BACKGROUND_TASK);
	if (ret != 0)
		bail_out("could not become regular task (huh?)");

	dealloc_arena(arena, arena_size);

	printf("ca_spin finished.\n");

	return 0;
}
