#!/usr/bin/env python
import os, signal
import copy
import math
import fractions
import random
import shlex, subprocess
import time, sys
import json

def parse_task_file(task_file):
	schedulers = []
	tasksets = dict()
	duration = None

	fd = open(task_file, 'r')

	for line in fd:
		a_line = line.strip()
		if a_line.startswith('#'):
			continue

		if a_line.startswith('SCHEDULERS'):
			token1 = a_line.split('=')
			if len(token1) != 2:
				raise Exception("wrong format: " + a_line)
			token2 = token1[1].split(',')
			schedulers += token2

			print "Schedulers: {}".format(schedulers)

		elif a_line.startswith('DURATION'):
			token1 = a_line.split('=')
			if len(token1) != 2:
				raise Exception("wrong format: " + a_line)
	
			duration = token1[1].strip()

			print "duration= {}".format(duration)

		elif a_line.startswith("TASKSET"):
			token1 = a_line.split('=')
			if len(token1) != 2:
				raise Exception("wrong format: " + a_line)

			token2 = token1[1].strip()
			tasksets[token2] = []

		else:
			token1 = a_line.split(',')
			if len(token1) == 10:
				task = token1[0]
				if tasksets[task] is None:
					print "not existing taskset: " + task
					continue

				if duration is None:
					print "DURATION must come first"
					raise Exception("DURATION is missing")

				a_task = {
					'taskset': task,
					'name': token1[1],
					'cpu': token1[2],
					'cache_partition': token1[3],
					'wcet': token1[4],
					'period': token1[5],
					'random': token1[6],
					'loop': token1[7],
					'duration': duration,
					'priority': token1[8],
					'wss': token1[9]}

				#print "a task: {}".format(a_task)
				tasksets[task].append(a_task)


	return schedulers, tasksets

def main(task_file):
	cpus = 4
	wcet = 1

	batch_name = task_file.split('.')[0]

	result_file = open(batch_name + '.csv', 'w')

	result_file.write("%15s, %12s, %12s, %12s, %12s, %12s\n" % \
		('Scheduler', 'taskset', 'cet-avg', 'cet-min', 'cet-max', 'dl-miss'))

	schedulers, tasksets = parse_task_file(task_file)

	for scheduler in schedulers:
		print "scheduler: " + scheduler

		init_arg = './init.sh {}'.format(scheduler)
		init = subprocess.Popen(init_arg.split())
		init.wait()

		time.sleep(1)

		for taskset, tasks in tasksets.iteritems():
			print "taskset: " + taskset

			debug_arg = 'cat /dev/litmus/log'
			debug_file = open("debug_log_{}-{}".format(scheduler, taskset), "w")

			debugcat = subprocess.Popen(debug_arg.split(), stdout=debug_file, stderr=None)

			task_list = []
			for taskinfo in tasks:
				if taskinfo['name'].startswith('rtspin'):
					task_arg = "./{} -w -q {} -C {} {} {} {}" \
						.format(taskinfo['name'],
							taskinfo['priority'],
							taskinfo['cache_partition'],
							taskinfo['wcet'],
							taskinfo['period'],
							taskinfo['duration'])
	
				else:
					#task_arg = "./{} -w -p {} -q {} -C {} -l {} -r {} {} {} {}" \
					task_arg = "./{} -w -q {} -C {} -l {} -r {} -S {} {} {} {}" \
						.format(taskinfo['name'],
				#			taskinfo['cpu'],
							taskinfo['priority'],
							taskinfo['cache_partition'],
							taskinfo['loop'],
							taskinfo['random'],
							taskinfo['wss'],
							taskinfo['wcet'],
							taskinfo['period'],
							taskinfo['duration'])
				print task_arg
				
				atask = subprocess.Popen(task_arg.split())
				task_list.append(atask)
				print "pid=" + str(atask.pid)

				if taskinfo['name'].endswith("spin"):
					target_pid = atask.pid
					print "target_pid=" + str(target_pid);

				wcet = taskinfo['wcet']

			trace_prefix = "{}-{}-{}" \
				.format(batch_name,
					scheduler,
					taskset)
 
			trace_arg = "st_trace -s " + trace_prefix

			trace = subprocess.Popen(trace_arg.split())

			time.sleep(1)

			rts_arg = './release_ts -f {}'.format(len(task_list))
			rts = subprocess.Popen(rts_arg.split())

			for t in task_list:
				t.wait()

			rts.wait()
		        trace.send_signal(signal.SIGUSR1)
		        trace.wait()

			time.sleep(10)
			debugcat.kill()
			subprocess.Popen("killall -9 cat", shell=True, stdout=None);
			debug_file.close()

			out_filename = "{}.out".format(trace_prefix)

			outfile = open(out_filename, 'w')

			job_stats_args = 'st_job_stats -p {} st-{}-*.bin' \
				.format(target_pid, trace_prefix)

			job_stats = subprocess.Popen(job_stats_args, shell=True, stdout=outfile)
			job_stats.wait()

			outfile.close()
			
			calc_arg = './calc2.py {}'.format(out_filename)
			calc = subprocess.Popen(calc_arg.split(), stdout=subprocess.PIPE, stderr=None)
			output, err = calc.communicate()

			output = output.strip()

			print output

			token = output.split(',')

			result_file.write("%15s, %12s, %12d, %12d, %12d, %12d\n" % \
				(scheduler, taskset, 
				int(token[0]), int(token[1]), 
				int(token[2]), int(token[3]))) 

			time.sleep(1)

	result_file.close()

if __name__ == "__main__":
	task_file = 'catasks.txt'

	if len(sys.argv) > 1 :
		task_file = sys.argv[1]

	main(task_file)

