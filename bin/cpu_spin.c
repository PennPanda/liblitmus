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
		"	ac_spin [COMMON-OPTS] WCET PERIOD DURATION\n"
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

	arena = mmap(0, size, PROT_READ | PROT_WRITE, flags, fd, 0);

	if (use_uncache_pages) {
		close(fd);
	}

	assert(arena);

	return arena;
}

static void dealloc_arena(cacheline_t* mem, size_t size) {
	int ret = munmap((void*)mem, size);

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

static void init_arena(cacheline_t* arena, size_t size, int shuffle) {
	int i;

	size_t num_arena_elem = size / sizeof(cacheline_t);

	if (shuffle) {

		for (i = 0; i < num_arena_elem; i++) {
			int j;
			for(j = 0; j < INTS_IN_CACHELINE; ++j) {
				arena[i].line[j] = i;
			}
		}

		while(1 < i--) {
			int j = randrange(0, i);

			cacheline_t temp = arena[j];
			arena[j] = arena[i];
			arena[i] = temp;
		}
	}
	else {
		for (i = 0; i < num_arena_elem; i++) {
			int j;
			int next = (i + 1) % num_arena_elem;
			for(j = 0; j < INTS_IN_CACHELINE; ++j) {
				arena[i].line[j] = next;
			}
		}
	}
}

static double loop_once(int wss, int shuffle) {
	double temp;
	int i = 0;
	
	for(i = 0; i < wss; i++)
	{
		if ( i % 2 == 0 )
			temp += i * i;
		else
			temp -= i * i;
	}
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
 
		while(iter++ < loops) {
			check_cp_setting(start);
			loop_once(wss, shuffle);
		}

                clock_gettime(CLOCK_REALTIME, &finish);
                printf("[WCET] pid=%d job_no=%d %ld %ld %.3fus\n",my_pid, job_no, finish.tv_sec - start.tv_sec, finish.tv_nsec - start.tv_nsec,
                    (finish.tv_sec - start.tv_sec) * 1.0 * (ONE_SEC/1000) + (finish.tv_nsec - start.tv_nsec) * 1.0 / 1000);

		sleep_next_period();
		return 1;
	}
}

#define OPTSTR "p:c:C:weq:r:l:S:"
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

	size_t arena_size = 0;
	int wss = 512;
	int shuffle = 1;
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

	srand(getpid());


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
	//wss = KB_IN_CACHE_PARTITION * (num_cache_partitions - 1) +
	//	KB_IN_CACHE_PARTITION / 64;
	if (size_kb == -1)
		wss = KB_IN_CACHE_PARTITION * (num_cache_partitions - 2);
	else
		wss = size_kb;
	printf("wss=%dKB\n", wss);

	//arena_size = wss * 1024;
	//arena = allocate_arena(arena_size, 0, 0);
	//init_arena(arena, arena_size, shuffle);

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

	//sleep(5);
	job_no = 1;
	arena_size = wss * 1024;
	arena = allocate_arena(arena_size, 0, 0);
	sleep_next_period();
	job_no++;
	init_arena(arena, arena_size, shuffle);
	//mlockall(MCL_CURRENT | MCL_FUTURE);
	sleep_next_period();
	job_no++;

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
