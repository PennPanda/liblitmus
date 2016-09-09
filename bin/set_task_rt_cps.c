/**
 * get rt_param of a specified pid
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Second, we include the LITMUS^RT user space library header.
 * This header, part of liblitmus, provides the user space API of
 * LITMUS^RT.
 */
#include "litmus.h"

/**
 * struct rt_task {
    lt_t        exec_cost;    
    lt_t        period;       
    lt_t        relative_deadline; 
    lt_t        phase;        
    unsigned int    num_cache_partitions;
    uint32_t    set_of_cp_init;    
    unsigned int    cpu;      
    unsigned int    priority; 
    task_class_t    cls;      
    budget_policy_t  budget_policy; 
    release_policy_t release_policy;

    unsigned long   page_colors;   
    unsigned int    color_index;
};
 */
void print_rt_param(struct rt_cache *param)
{
    printf("set_of_cps:0x%lx\n",
            (long) param->set_of_cps);
}

int main(int argc, char** argv)
{
	struct rt_cache param;
	pid_t pid;
    uint32_t new_cps;
    int is_flush;

	if ( argc < 3 )
	{
		printf("[usage] set_task_rt_cps pid new_cp_setting is_flush\n");
		exit(1);
	}
	pid = atoi(argv[1]);
	if (pid == 0)
	{
		pid = gettid();
	}
    sscanf(argv[2], "%x", &new_cps);
    is_flush = atoi(argv[3]);
    if ( is_flush < 0 || is_flush > 1 )
    {
        printf("is_flush must be 0 or 1\n");
        exit(1);
    }

	printf("pid=%d new_cps=%x is_flush=%d\n", pid, new_cps, is_flush);

	if (get_rt_task_cps(pid, &param))
	{
		printf("get_rt_task_param fails\n");
		exit(1);
	}

    printf("----Old rt_params----\n");
	print_rt_param(&param);

    printf("set_rt_task_param:pid=%d now\n", pid);
    param.set_of_cps = new_cps;
    param.flush = is_flush;
    if (set_rt_task_cps(pid, &param))
    {
        printf("set_rt_task_cps fails\n");
        exit(2);
    }

    printf("----Current rt_params----\n");
	if (get_rt_task_cps(pid, &param))
	{
		printf("get_rt_task_param fails\n");
		exit(1);
	}
	print_rt_param(&param);

	return 0;
}
