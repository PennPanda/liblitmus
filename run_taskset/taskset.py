#!/usr/bin/python

import sys
import signal
import subprocess

import config
from config import printlog

class TaskInfo():
	def __init__(self, app, param, pollute):
		self.app = app
		self.param = param
		self.pollute = pollute

	def __repr__(self):
		return 'app={}, pollute={}, params={}'.format(self.app, self.pollute, self.param)

def load():
	pass

def run(scheduler, taskset, prefix):
	printlog(1, "Run a taskset: %s" % prefix)

	init_args = '%s %s' % (config.conf['init_shell'], scheduler)
	init_proc = subprocess.Popen(init_args, shell=True, 
		stdout=config.log, stderr=config.log)
	init_proc.wait()

	main_procs = []
	index = 0

	for ti in taskset:
		printlog(1, "Task: %s" % ti)

		main_args = '%s %s' % (ti.app, ti.param)
		main_proc = subprocess.Popen(main_args.split(), 
			stdout=config.log, stderr=config.log)

		if ti.pollute == 0:
			main_procs.append(main_proc)

		index += 1

	trace_args = '%s -s %s' % (config.conf['st_trace'], prefix)
	trace_proc = subprocess.Popen(trace_args.split(), 
		stdout=config.log, stderr=config.log)

	rts_args = '%s -f %d' % (config.conf['release_ts'], len(taskset))
	rts_proc = subprocess.Popen(rts_args.split(),
		stdout=config.log, stderr=config.log)

	rts_proc.wait()

	for p in main_procs:
		p.wait()

	trace_proc.send_signal(signal.SIGUSR1)
	trace_proc.wait()

	results = None

	if config.conf['do_analysis']:
		pidlist = []
		for p in main_procs:
			pidlist.append(p.pid)

		results = analysis(prefix, pidlist)

	# move bin file to output folder
	mv_args = 'mv -f st-%s-?.bin %s' % \
		(prefix, config.conf['output_dir'])
	mv_proc = subprocess.Popen(mv_args, shell=True)
	mv_proc.wait()

	printlog(1, "done")

	return results

def analysis(prefix, pidlist):
	printlog(1, "Analyze result:")

	results = []

	index = 0
	for pid in pidlist:
		js_filename = '%s/%s-%d-PID_%d_jobs.log' % \
			(config.conf['output_dir'], prefix, index, pid)

		js_args = '%s -p %d st-%s-?.bin' % \
			(config.conf['st_job_stats'], pid, prefix)

		with open(js_filename, 'w') as outfile:
			js_proc = subprocess.Popen(js_args, shell=True, 
				stdout=outfile, stderr=config.log)

		js_proc.wait()
		
		cl_args = '%s %s' % (config.conf['calc_app'], js_filename)
		cl_proc = subprocess.Popen(cl_args.split(), 
			stdout=subprocess.PIPE, stderr=config.log)
		
		output, err = cl_proc.communicate()
		output = output.strip()

		token = output.split(',')

		results.append({
			'index': index,
			'pid': pid,
			'avg': int(token[0]),
			'min': int(token[1]),
			'max': int(token[2]),
			'dlmiss': int(token[3])})

		index += 1

	printlog(1, results)

	return results

