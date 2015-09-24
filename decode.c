#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>


typedef unsigned long long uint64_t;
typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

struct timestamp {
    uint64_t        timestamp:48;
    uint64_t        pid:16;
    uint32_t        seq_no;
    uint8_t         cpu;
    uint8_t         event;
    uint8_t         task_type:2;
    uint8_t         irq_flag:1;
    uint8_t         irq_count:5;
};

int main(int argc, char* argv[])
{
	FILE *fp = NULL;
	struct timestamp ts;

	if (argc < 2) {
		printf ("Usage: decode {msg_trace_file}\n");
		exit(0);
	}

	fp = fopen(argv[1], "rb");

	while (!feof(fp)) {
		if (fread(&ts, sizeof(ts), 1, fp) < 1) {
			break;
		}

		printf("%llu, %llu, %u, %u, %u, %u, %u, %u\n",
			(uint64_t)ts.timestamp, (uint64_t)ts.pid, ts.seq_no, 
			ts.cpu, ts.event,
			ts.task_type, ts.irq_flag, ts.irq_count);
	}

	fclose(fp);

	return 0;
}

