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

typedef struct cacheline {
	int line[INTS_IN_CACHELINE];
} __attribute__((aligned(CACHELINE_SIZE))) cacheline_t;

static cacheline_t *arena = NULL;
static int loops = 10;
static int hot_wss_B = 0;
static int size_hot_wss = -1;
static int hot_loops = 0;

#define UNCACHE_DEV "/dev/litmus/uncache"
static cacheline_t* allocate_arena(size_t size, int use_huge_pages, int use_uncache_pages) {

	int flags = MAP_PRIVATE | MAP_POPULATE;
	cacheline_t* arena = NULL;
	int fd;

	if (use_huge_pages) {
		flags |= MAP_HUGETLB;
	}

	if (use_uncache_pages) {
		fd = open(UNCACHE_DEV, O_RDWR|O_SYNC);
		if (fd == -1) {
			bail_out("Failed to open uncache device.");
		}
	}
	else {
		fd = -1;
		flags |= MAP_ANONYMOUS;
	}

	//arena = mmap(0, size, PROT_READ | PROT_WRITE, flags, fd, 0);
	arena = (cacheline_t*) malloc(size);

	if (use_uncache_pages) {
		close(fd);
	}

	assert(arena);

	return arena;
}

static void dealloc_arena(cacheline_t* mem, size_t size) {
	//int ret = munmap((void*)mem, size);
	int ret = 0;
	
	if (mem) 
		free((void*) mem);

	if (ret != 0) {
		bail_out("munmap() error");
	}
}

static int randrange(int min, int max) {
	int limit = max - min;
	int divisor = RAND_MAX / limit;
	int retval;

	do {
		retval = rand() / divisor;
	} while(retval == limit);

	retval += min;

	return retval;
}

/* Use Global Variable hot_wss_B */
static void init_arena(cacheline_t* arena, size_t size, int shuffle) {
	int i;

	size_t num_arena_elem = size / sizeof(cacheline_t);
	size_t num_hot_arena_elem = hot_wss_B / sizeof(cacheline_t);

	if (shuffle) {

		for (i = 0; i < num_arena_elem; i++) {
			int j;
			for(j = 0; j < INTS_IN_CACHELINE; ++j) {
				arena[i].line[j] = i;
			}
		}

		/* Each cache line has 8 int,
		 * 0th int used to enumerate whole array for l loops
		 * 1th int used to enumerate the first hot_wss_B array for L loops */
		while(1 < i--) {
			int j = randrange(0, i);
			int temp = arena[j].line[0];
			arena[j].line[0] = arena[i].line[0];
			arena[i].line[0] = temp;
		}
		i = num_hot_arena_elem;
		while(1 < i--) {
			int j = randrange(0, i);

			int temp = arena[j].line[1];
			arena[j].line[1] = arena[i].line[1];
			arena[i].line[1] = temp;
		}
	}
	else {
		for (i = 0; i < num_arena_elem; i++) {
			int next = (i + 1) % num_arena_elem;
			arena[i].line[0] = next; 
		}
		for (i = 0; i < num_hot_arena_elem; i++) {
			int next = (i + 1) % num_arena_elem;
			arena[i].line[1] = next; 
		}
	}
}

static cacheline_t* cacheline_start(int wss, int shuffle) {
	//return arena + (shuffle * randrange(0, ((wss * 1024) / sizeof(cacheline_t))));
	return arena;
}

static int cacheline_walk(cacheline_t *mem, int wss) {
	int sum, i, next;

	int numlines = wss * CACHELINES_IN_1KB;

	sum = 0;

	next = mem - arena;

	/* Iterate over whole array */
	for (i = 0; i < numlines; i++) {
		next = arena[next].line[0];
		sum -= next;
	}

	return sum;
}

static int cacheline_walk_hot(cacheline_t *mem, int wss) {
	int sum, i, next;

	int num_hot_lines = hot_wss_B / sizeof(cacheline_t);

	sum = 0;

	next = mem - arena;

	/* Iterate over hot_wss_B only */
	for (i = 0; i < num_hot_lines; i++) {
		next = arena[next].line[1];
		sum += next;
	}
	if (flag_printf >= 2)
		printf("sum=%d\n", sum);
	
	return sum;
}

static int loop_cpu_once(int wcet) {
	double sum;
	int i, j;

	for (j = 0; j < wcet; j++)
	{
		/* 1us */
		for (i = 0; i < 130; i++)
		{
			sum += i*i;
			sum -= (i - 1) * (i + 1);
		}
	}

	return 0;
}

static int loop_once(int wss, int shuffle) {
	cacheline_t *mem;
	int temp;
	
	/* Should always start with the first element */
	mem = cacheline_start(wss, shuffle);
	temp = cacheline_walk(mem, wss);

	return temp; 
}

static int loop_hot_once(int wss, int shuffle) {
	cacheline_t *mem;
	int temp;
	
	/* Should always start with the first element */
	mem = cacheline_start(wss, shuffle);
	temp = cacheline_walk_hot(mem, wss);

	return temp; 
}

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
		printf("pid=%d job_no=%d cpu_prev=%d cpu_cur=%d cp_prev=0x%x cp_cur=0x%x dur_invalidt=%.3fus\n",
			my_pid, job_no, cpu_prev, cpu, cp_prev, cp_cur, dur_tmp);
	}
}
//////////////////////////////////////////
void die(char *x){ perror(x); exit(1); };
#define ONE_SEC 1000000000L
#define BS	1024
static int job(int wss, int shuffle, double exec_time, double program_end)
{
	if (wctime() > program_end)
		return 0;
	else {
		register unsigned int iter = 0;
        	struct timespec start, finish;

		invalid_cp_flag = 0;
                clock_gettime(CLOCK_REALTIME, &start);
 
		/* Walk whole array */
		while(iter++ < loops) {
			//check_cp_setting(start);
			/* each cp takes 100us if cache hit */
			if (use_cpu_loop)
				loop_cpu_once(100 * NUM_CP);
			loop_once(wss, shuffle);
		}
		iter = 0;
		while(iter++ < hot_loops) {
			//check_cp_setting(start);
			/* each cp takes 100us if cache hit */
			if (use_cpu_loop)
				loop_cpu_once(100 * NUM_CP);
			loop_hot_once(wss, shuffle);
		}

                clock_gettime(CLOCK_REALTIME, &finish);
		if (flag_printf == 1)
                	printf("[WCET] pid=%d job_no=%d %ld %ld %.3fus\n",my_pid, job_no, finish.tv_sec - start.tv_sec, finish.tv_nsec - start.tv_nsec,
                    		(finish.tv_sec - start.tv_sec) * 1.0 * (ONE_SEC/1000) + (finish.tv_nsec - start.tv_nsec) * 1.0 / 1000);

		sleep_next_period();
		return 1;
	}
}

static void initialize(size_t arena_size, int shuffle) {
       	struct timespec start, finish;

        clock_gettime(CLOCK_REALTIME, &start);
 
	arena = allocate_arena(arena_size, 0, 0);
	init_arena(arena, arena_size, shuffle);
	
        clock_gettime(CLOCK_REALTIME, &finish);
        printf("init: %ld %ld %ld\n", finish.tv_sec - start.tv_sec, 
		finish.tv_nsec - start.tv_nsec,
        	(finish.tv_sec - start.tv_sec)*ONE_SEC + 
		(finish.tv_nsec - start.tv_nsec));

	sleep_next_period();
}

#define OPTSTR "p:c:C:weq:r:l:s:L:S:U:f:D:P:"
int main(int argc, char** argv)
{
	int ret;
	lt_t wcet;
	lt_t period;
	lt_t deadline;
	double wcet_ms, period_ms, deadline_ms;
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
    int set_of_cp_init;

	int wss = 0;
	int shuffle = 1;
	size_t arena_size;
	int size_kb = -1;
	int ch;

	job_no = 0;

	progname = argv[0];

	while ((opt = getopt(argc, argv, OPTSTR)) != -1) {
		switch (opt) {
		case 'D':
			deadline_ms = atoi(optarg);
			break;
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
        case 'P':
            sscanf(optarg, "%x", &set_of_cp_init);
            if ( set_of_cp_init == 0 )
                usage("Invalid initial cache partition seting. must be at least 2 cps");
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
		case 's':
			size_kb = atoi(optarg);
			break;
		case 'S':
			size_hot_wss = atoi(optarg);
			break;
		case 'l': /* loops for all working set size */
			loops = atoi(optarg);
			break;
		case 'L': /* loops for hot working set size only */
			hot_loops = atoi(optarg);
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

    printf("MAX_CACHE_PARTITIONS=%d\n", MAX_CACHE_PARTITIONS);

	wcet   = ms2ns(wcet_ms);
	period = ms2ns(period_ms);
	deadline = ms2ns(deadline_ms);
	if (wcet <= 0)
		usage("The worst-case execution time must be a "
				"positive number.");
	if (period <= 0)
		usage("The period must be a positive number.");
	if (deadline <= 0)
		usage("The deadline must be a positive number.");
	if (wcet > period || wcet > deadline) {
		usage("The worst-case execution time must not "
				"exceed the period or deadline.");
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
	if (size_hot_wss == -1)
		hot_wss_B = 0;
	else
		hot_wss_B = size_hot_wss * 1024;
	printf("wss=%dKB\n", wss);
	arena_size = wss * 1024;

	init_rt_task_param(&param);
	param.exec_cost = wcet;
	param.period = period;
	param.relative_deadline = deadline;
	param.priority = priority;
	param.cls = class;
	param.budget_policy = (want_enforcement) ?
			PRECISE_ENFORCEMENT : NO_ENFORCEMENT;
	if (migrate)
		param.cpu = cluster; //domain_to_first_cpu(cluster);

	param.num_cache_partitions = num_cache_partitions;
    param.set_of_cp_init = set_of_cp_init;

	ch = getchar();
	printf("input char: %d\n", ch);

	ret = set_rt_task_param(gettid(), &param);
	if (ret < 0)
		bail_out("could not setup rt task params");

	ret = get_rt_task_param(gettid(), &param_tmp);
	if (ret < 0)
		bail_out("could not get rt task params");
	printf("MX: num_cache_partitions=%d\n", param_tmp.num_cache_partitions);

	init_litmus();

	//printf("MX:before task_mode(LITMUS_RT_TASK)\n");
	ret = task_mode(LITMUS_RT_TASK);
	//printf("MX:after task_mode(LITMUS_RT_TASK)\n");
	if (ret != 0)
		bail_out("could not become RT task");

	if (wait) {
		ret = wait_for_ts_release();
		if (ret != 0)
			bail_out("wait_for_ts_release()");
	}

	initialize(arena_size, shuffle);

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
