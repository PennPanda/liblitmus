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

#include <linux/perf_event.h>
#include <asm/unistd.h>

#include "litmus.h"
#include "common.h"

#define NUM_CACHE_PARTITIONS 	8

static int fddev = -1;

__attribute__((constructor)) static void init(void)
{
	static struct perf_event_attr attr;
	attr.type = PERF_TYPE_HARDWARE;
	attr.config = PERF_COUNT_HW_CPU_CYCLES;
	fddev = syscall(__NR_perf_event_open, &attr, 0, -1, -1, 0);
}

__attribute__((destructor)) static void finish(void)
{
	close(fddev);
}

static inline long long cpucycles(void)
{
	long long result = 0;
	if (read(fddev, &result, sizeof(result)) < sizeof(result)) return 0;

	return result;
}

static void usage(char *error) {
	fprintf(stderr, "Error: %s\n", error);
	fprintf(stderr,
		"Usage:\n"
		"	flush_cache -C {cache partition} -M {method=0, 1, 2} -L {loop_count}\n"
		);
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
static int cache_partitions = 1;
static int method = 0;
static int sparse = 0;

static unsigned int way_lock[2][17] = {{
	0x0000, //0
	0x0001, //1
	0x0003, //2
	0x0007, //3
	0x000f, //4
	0x001f, //5
	0x003f, //6
	0x007f, //7
	0x00ff, //8
	0x01ff, //9
	0x03ff, //10
	0x07ff, //11
	0x0fff, //12
	0x1fff, //13
	0x3fff, //14
	0x7fff, //15
	0xffff  //16
}, {
	0x0000, //0
	0x1000, //1
	0x1100, //2
	0x1110, //3
	0x1111, //4
	0x5111, //5
	0x5511, //6
	0x5551, //7
	0x5555, //8
	0xd555, //9
	0xdd55, //10
	0xddd5, //11
	0xdddd, //12
	0xfddd, //13
	0xffdd, //14
	0xfffd, //15
	0xffff  //16
}};

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
		if (method == 2) {
			arena[next].line[1] += sum;
		}
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
#define ONE_SEC 1000000000
#define CPU_FREQ 996000000
#define CYCLE_TO_NS(x) (1.0 * (x) * ONE_SEC / CPU_FREQ)
static int job(int wss, int shuffle, double exec_time, double program_end)
{
	if (wctime() > program_end)
		return 0;
	else {

		register int iter = 0;
		//struct timespec start, finish;
		unsigned int ways = way_lock[sparse][cache_partitions];
		long long cstart, cend;
		unsigned int kernel = 0; //cycles for calling l2x0_flush_cache_ways()
		long long total, syscall;

		flush_cache_ways(ways, &kernel);

		if (method == 0) {

			printf("=========== idle ==========\n");

			for(iter = 0; iter < loops; ++iter) {
				//clock_gettime(CLOCK_REALTIME, &start);
				cstart = cpucycles();
				flush_cache_ways(ways, &kernel);
				cend = cpucycles();
				//clock_gettime(CLOCK_REALTIME, &finish);

				//cstart = start.tv_sec * ONE_SEC + start.tv_nsec;
				//cend = finish.tv_sec * ONE_SEC + finish.tv_nsec;

				total = cend - cstart;
				syscall = total - kernel;

				printf("kernel %8u cycles %12.3f ns, "
					"syscall %6lld cycles %10.3f ns, " 
					"total %8lld cycles %12.3f ns\n",
					kernel, CYCLE_TO_NS(kernel),
					syscall, CYCLE_TO_NS(syscall),
					total, CYCLE_TO_NS(total));
			}


			method = 1;
			sleep_next_period();
			return 1;
		}
		else if (method == 1) {
			printf("=========== read ==========\n");

			for(iter = 0; iter < loops; ++iter) {
				loop_once(wss, shuffle);

				//clock_gettime(CLOCK_REALTIME, &start);
				cstart = cpucycles();
				flush_cache_ways(ways, &kernel);
				cend = cpucycles();
				//clock_gettime(CLOCK_REALTIME, &finish);

				//cstart = start.tv_sec * ONE_SEC + start.tv_nsec;
				//cend = finish.tv_sec * ONE_SEC + finish.tv_nsec;

				total = cend - cstart;
				syscall = total - kernel;

				printf("kernel %8u cycles %12.3f ns, "
					"syscall %6lld cycles %10.3f ns, " 
					"total %8lld cycles %12.3f ns\n",
					kernel, CYCLE_TO_NS(kernel),
					syscall, CYCLE_TO_NS(syscall),
					total, CYCLE_TO_NS(total));
			}

			method = 2;
			sleep_next_period();
			return 1;
		}
		else {
			printf("=========== write ==========\n");

			for(iter = 0; iter < loops; ++iter) {
				loop_once(wss, shuffle);

				//clock_gettime(CLOCK_REALTIME, &start);
				cstart = cpucycles();
				flush_cache_ways(ways, &kernel);
				cend = cpucycles();
				//clock_gettime(CLOCK_REALTIME, &finish);

				//cstart = start.tv_sec * ONE_SEC + start.tv_nsec;
				//cend = finish.tv_sec * ONE_SEC + finish.tv_nsec;

				total = cend - cstart;
				syscall = total - kernel;

				printf("kernel %8u cycles %12.3f ns, "
					"syscall %6lld cycles %10.3f ns, " 
					"total %8lld cycles %12.3f ns\n",
					kernel, CYCLE_TO_NS(kernel),
					syscall, CYCLE_TO_NS(syscall),
					total, CYCLE_TO_NS(total));
			}


			sleep_next_period();
			return 0;
		}
		
	}
}

static void initialize(size_t arena_size, int shuffle)
{

	arena = allocate_arena(arena_size, 0, 0);
	init_arena(arena, arena_size, shuffle);

	sleep_next_period();
}

#define OPTSTR "p:c:C:weq:r:l:S:s"
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
	int wss = 64;
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
		case 'S':
			wss = atoi(optarg);
			break;
		case 'e':
			want_enforcement = 1;
			break;
		case 'r':
			shuffle = atoi(optarg);
			if (shuffle) {
				shuffle = 1;
			}
			break;
		case 'l':
			loops = atoi(optarg);
			break;
		case 's':
			sparse = 1;
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

	arena_size = wss * 1024;
	cache_partitions = num_cache_partitions;
	method = 0;

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

	initialize(arena_size, shuffle);

	printf("CP=%d, WSS=%dKB, SPARSE_ways=%d\n", cache_partitions, wss, sparse);

	start = wctime();

	while (job(wss, shuffle, wcet_ms * 0.001, start + duration));

	ret = task_mode(BACKGROUND_TASK);
	if (ret != 0)
		bail_out("could not become regular task (huh?)");

	dealloc_arena(arena, arena_size);

	printf("ca_thrash finished.\n");

	return 0;
}
