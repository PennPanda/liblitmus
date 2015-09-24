#include <stdio.h>
#include <time.h>

int main(int argc, char* argv[])
{
	int i = 0;
	double sum;
	struct timespec start, finish;
	double lat;
	long target_lat;

	if (argc <= 1)
	{
		printf("[Usage] ./measure_cpu_latency exe");
		exit(1);
	}

	target_lat = atoi(argv[1]);

	clock_gettime(CLOCK_REALTIME, &start);
	do {
		sum += i * i;
		sum -= (i - 1) * (i + 1);
		clock_gettime(CLOCK_REALTIME, &finish);
		lat = (finish.tv_sec - start.tv_sec) * 1000 * 1000 + (finish.tv_nsec - start.tv_nsec) * 1.0 / 1000;
		if (lat >= target_lat)
			break;
		i++;
	} while(1);

	printf("latency=%dus needs i = %d\n", target_lat, i);
}
