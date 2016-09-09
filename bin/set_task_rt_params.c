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
void print_rt_param(struct rt_task *param)
{
	printf("exec_cost:%lld period:%lld relative_deadline:%lld "
		   "phase:%lld num_cache_partitions:%d set_of_cp_init:%lx "
		   "cpu:%d priority:%d cls:%d budget_policy:%d "
		   "release_policy:%d page_colors:%ld color_index:%d\n",
		   (long long) param->exec_cost, (long long) param->period, (long long) param->relative_deadline,
		   (long long) param->phase, param->num_cache_partitions, (long) param->set_of_cp_init,
		   param->cpu, param->priority, param->cls, param->budget_policy,
		   param->release_policy, param->page_colors, param->color_index);
}

int main(int argc, char** argv)
{
	struct rt_task param;
	pid_t pid;
    uint32_t new_cps;

	if ( argc < 3 )
	{
		printf("[usage] set_task_rt_params pid new_cp_setting\n");
		exit(1);
	}
	pid = atoi(argv[1]);
	if (pid == 0)
	{
		pid = gettid();
	}
    sscanf(argv[2], "%x", &new_cps);

	printf("pid=%d new_cps=%x\n", pid, new_cps);
	if (get_rt_task_param(pid, &param))
	{
		printf("get_rt_task_param fails\n");
		exit(1);
	}

    printf("----Old rt_params----\n");
	print_rt_param(&param);

    printf("set_rt_task_param:pid=%d now\n", pid);
    param.set_of_cp_init = new_cps;
    if (set_rt_task_param(pid, &param))
    {
        printf("set_rt_task_param fails\n");
        exit(2);
    }

    printf("----Current rt_params----\n");
	if (get_rt_task_param(pid, &param))
	{
		printf("get_rt_task_param fails\n");
		exit(1);
	}
	print_rt_param(&param);

	return 0;
}