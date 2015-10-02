#!/usr/bin/python

import os, os.path
import sys
import json

import config
import loopcount
import taskset

from config import printlog


def load_profiles():

	dir = config.conf['taskset_dir']

	profiles = dict()

	for profile in config.conf['taskset_profiles']:
		profiles[profile] = load_utilizations(dir, profile)

	return profiles

def load_utilizations(basedir, subdir):
	dir = '%s/%s' % (basedir, subdir)

	utilizations = dict()

	for entry in os.listdir(dir):
		if os.path.isdir(dir + '/' + entry):
			utilizations[entry] = load_tasksets(dir, entry)

	return utilizations

def load_tasksets(basedir, subdir):
	dir = '%s/%s' % (basedir, subdir) 

	suffix = '-%s.txt' % (subdir)

	tasksets = dict()
	
	for entry in os.listdir(dir):
		if entry.endswith(suffix):
			ti = entry.split('-')[0]
			tasksets[ti] = load_tasks(dir, entry)

	return tasksets

def load_tasks(dir, file):
        tasks = dict()

	fullpath = '%s/%s' % (dir, file)

        with open(fullpath, 'r') as data_file:
                for line in data_file:
                        if line.startswith('#'):
                                continue

                        token = line.split()

                        index = token[1]
                        period = token[2]
                        wcet = token[3]
                        cp = token[4]

                        tasks[index] = {
                                'index': int(index),
                                'period': int(float(period)),
                                'wcet' : int(float(wcet)),
                                'cp': int(cp)}

        return tasks


def load():

	profiles = load_profiles()

	return profiles

def run(profiles):
	for p in profiles:
		profile = profiles[p]
		prefix = p

		printlog(1, "Run Profile: {}".format(prefix))

		run_utilizations(prefix, profile)


def run_utilizations(prefix, utils):
	for un in sorted(utils):
		tasksets = utils[un]
		subprefix = '%s#%s' % (prefix, un)

		printlog(1, "Run Utilization: {}".format(subprefix))

		run_tasksets(subprefix, tasksets)

def run_tasksets(prefix, tasksets):
	for ts in sorted(tasksets):
		# only run up to max_tasksets configuration
		if int(ts) > config.conf['max_tasksets']:
			continue

		taskset = tasksets[ts]
		subprefix = '%s#%s' % (prefix, ts)

		printlog(1, "Run Taskset: {}".format(subprefix))

		run_taskset(subprefix, taskset)

def run_taskset(prefix, tset):
	tilist = build_taskinfos(tset)

	for scheduler in config.conf['schedulers']:
		subprefix = '%s#%s' % (prefix, scheduler)

		results = taskset.run(scheduler, tilist, subprefix)
		if results is not None:
			printlog(1, "Result: {}".format(results))
	

def build_taskinfos(taskset):
	tilist = []

	for ti in sorted(taskset):
		task = taskset[ti]

		tilist.append(build_taskinfo(task))

	tilist.append(build_thrashtask())

	return tilist

def build_taskinfo(task):
	app = config.conf['main_app']

	cp = task['cp']
	wss = cp * 64
	wcet = task['wcet']
	period = task['period']

	if loopcount.exists(cp, wcet):
		loop = loopcount.get(cp, wcet)
		printlog(1, "Using pre-caclulated loopcount={}".format(loop))
	else:
		printlog(1, "No loopcount exists. Measuring it.")
		loop = loopcount.measure(cp, wcet)

	priority = task['index'] + 1
	duration = config.conf['duration']

	params = '-w -C %d -S %d -l %d -r 1 -q %d %d %d %d' % \
		(cp, wss, loop, priority, wcet, period, duration)

	return taskset.TaskInfo(app, params, 0)

def build_thrashtask():
	app = config.conf['pollute_app']
	
	cp = 0
	wss = 1024
	wcet = 99
	period = 100
	loop = 1000
	priority = 255
	duration = config.conf['duration']

			
	params = '-w -C %d -S %d -l %d -r 0 -q %d %d %d %d' % \
		(cp, wss, loop, priority, wcet, period, duration)

	return taskset.TaskInfo(app, params, 1)

def main(argv):
	profiles = load()

	#with open('log.txt', 'w') as outfile:
	#	json.dump(profiles, outfile, sort_keys=True, indent=4)

	run(profiles)

if __name__ == "__main__":
	main(sys.argv)

