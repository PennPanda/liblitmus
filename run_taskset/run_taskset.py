#!/usr/bin/python

import os, os.path
import sys
import json

import config
import loopcount
import taskset

from config import printlog

profiles = None

def load_profiles():

	dir = config.conf['taskset_dir']

	profiles = dict()

	for profile in config.conf['taskset_profiles']:
		profiles[profile] = {
			'profile': profile,
			'utilizations': load_utilizations(dir, profile)
		}

	return profiles

def load_utilizations(basedir, subdir):
	dir = '%s/%s' % (basedir, subdir)

	utilizations = dict()

	for entry in os.listdir(dir):
		if os.path.isdir(dir + '/' + entry):
			utilizations[entry] = {
				'utilization': entry,
				'tasksets' : load_tasksets(dir, entry)
			}

	return utilizations

def load_tasksets(basedir, subdir):
	dir = '%s/%s' % (basedir, subdir) 

	suffix = '-%s.txt' % (subdir)

	tasksets = dict()
	
	for entry in os.listdir(dir):
		if entry.endswith(suffix):
			ti = entry.split('-')[0]
			tasksets[ti] = {
				'taskset': ti,
				'complete': 0,
				'tasks': load_tasks(dir, entry)
			}

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
	global profiles

	profiles = load_profiles()

def save():
	global profiles

	pathname = '{}/profiles.json'.format(config.conf['output_dir'])

	with open(pathname, 'w') as outfile:
		json.dump(profiles, outfile, sort_keys=True, indent=4)

def run():
	global profiles

	for p in profiles:
		profile = profiles[p]
		prefix = p

        # save duration and schedulers information to profiles
        profile['duration'] = config.conf['duration']
        profile['schedulers'] = config.conf['schedulers']

		printlog(1, "Run Profile: {}".format(prefix))

		run_utilizations(prefix, profile['utilizations'])


def run_utilizations(prefix, utils):
	for ut in sorted(utils):
		util = utils[ut]

		subprefix = '%s#%s' % (prefix, util)

		printlog(1, "Run Utilization: {}".format(subprefix))

		run_tasksets(subprefix, util['tasksets'])

def run_tasksets(prefix, tasksets):
	for ts in sorted(tasksets):
		# only run up to max_tasksets configuration
		if int(ts) > config.conf['max_tasksets']:
			continue

		taskset = tasksets[ts]
		subprefix = '%s#%s' % (prefix, ts)

		printlog(1, "Run Taskset: {}".format(subprefix))

		run_taskset(subprefix, taskset['tasks'])

		# set complete flag
		taskset['complete'] = 1

		save()

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

    if config.conf['use_pollute_task']:
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
	load()

	# save first
	save()

	run()

if __name__ == "__main__":
	main(sys.argv)

