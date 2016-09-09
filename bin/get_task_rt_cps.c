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

	if ( argc < 2 )
	{
		printf("[usage] get_task_rt_cps pid\n");
		exit(1);
	}
	pid = atoi(argv[1]);
	if (pid == 0)
	{
		pid = gettid();
	}

	printf("pid=%d\n", pid);
	if (get_rt_task_cps(pid, &param))
	{
		printf("get_rt_task_cps fails\n");
		exit(1);
	}

	print_rt_param(&param);

	return 0;
}
