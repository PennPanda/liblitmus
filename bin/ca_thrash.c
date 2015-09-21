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

#include "litmus.h"
#include "common.h"

#define NUM_CACHE_PARTITIONS 	8

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
//////////////////////////////////////////

#define KB_IN_CACHE_PARTITION	64
#define WSS 1024
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

static cacheline_t* cacheline_start(int wss, int shuffle) {
	return arena + (shuffle * randrange(0, ((WSS * 1024) / sizeof(cacheline_t))));
}

static int cacheline_walk(cacheline_t *mem, int wss) {
	int sum, i, next;

	int numlines = WSS * CACHELINES_IN_1KB;

	sum = 0;

	next = mem - arena;

	for (i = 0; i < numlines; i++) {
		next = arena[next].line[0];
		sum += next;
	}

	return sum;
}

static int loop_once(int wss, int shuffle) {
	cacheline_t *mem;
	int temp;
	
	mem = cacheline_start(WSS, shuffle);
	temp = cacheline_walk(mem, WSS);

	return temp; 
}

//////////////////////////////////////////

static int job(int wss, int shuffle, double exec_time, double program_end)
{
	if (wctime() > program_end)
		return 0;
	else {

                double last_loop = 0, loop_start;
                double start = cputime();
                double now = cputime();
                while(now + last_loop < start + exec_time) {
                        loop_start = now;
                        loop_once(wss, shuffle);
                        now = cputime();
                        last_loop = now - loop_start;
                }

		sleep_next_period();
		return 1;
	}
}

#define OPTSTR "p:c:C:weq:r:l:"
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
	int wss = 1024;
	int shuffle = 0;

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
			break;
		case 'e':
			want_enforcement = 1;
			break;
		case 'r':
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
		if (ret < 0) {
			
			printf("could not migrate to target partition or cluster.");
			bail_out("could not migrate to target partition or cluster.");
		}
	}

	//set up wss based on num_cache_partitions
	//wss = KB_IN_CACHE_PARTITION * (num_cache_partitions - 1) +
	//	KB_IN_CACHE_PARTITION / 2;

	//arena_size = WSS * 1024;
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
	if (ret < 0) {
		printf("could not setup rt task params");
		bail_out("could not setup rt task params");
	}

	ret = get_rt_task_param(gettid(), &param_tmp);
	if (ret < 0) {
		printf("could not get rt task params");
		bail_out("could not get rt task params");
	}
	printf("MX: num_cache_partitions=%d\n", param_tmp.num_cache_partitions);

	init_litmus();

	printf("MX:before task_mode(LITMUS_RT_TASK)\n");
	ret = task_mode(LITMUS_RT_TASK);
	printf("MX:after task_mode(LITMUS_RT_TASK)\n");
	if (ret != 0) {
		printf("could not become RT task");
		bail_out("could not become RT task");
	}

	if (wait) {
		ret = wait_for_ts_release();
		if (ret != 0)
			bail_out("wait_for_ts_release()");
	}

	sleep(5);
	arena_size = WSS * 1024;
	arena = allocate_arena(arena_size, 0, 0);
	init_arena(arena, arena_size, shuffle);

	mlockall(MCL_CURRENT | MCL_FUTURE);

	start = wctime();

	while (job(wss, shuffle, wcet_ms * 0.001, start + duration));

	ret = task_mode(BACKGROUND_TASK);
	if (ret != 0)
		bail_out("could not become regular task (huh?)");

	dealloc_arena(arena, arena_size);

	printf("ca_thrash finished.\n");

	return 0;
}
