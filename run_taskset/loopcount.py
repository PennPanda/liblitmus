#!/usr/bin/python

import json
import os.path
import subprocess
import signal
import sys

import config
import taskset

from config import printlog


_mapfile_format="loops_map_cp_%d.json"
_lc_map = dict()

def _initialize_cp_map(cp):
	cp_map = {
		'cp': cp,
		'wcets': dict()}

	return cp_map

def _load_cp_map(cp):
	filename = config.conf['data_dir'] + '/' + _mapfile_format % cp

	if not os.path.exists(filename):
		return _initialize_cp_map(cp)

	printlog(0, 'Loading CP-Map file: %s' % filename)

	with open(filename, 'r') as data_file:
		data = json.load(data_file)

	return data

def _load_all():
	global _lc_map

	min_cp = config.conf['min_cp']
	max_cp = config.conf['max_cp']

	for cp in range(min_cp, max_cp):
		_lc_map[str(cp)] = _load_cp_map(cp)
	
def _save_cp_map(cp, cp_map):
	filename = config.conf['data_dir'] + '/' + _mapfile_format % cp

	with open(filename, 'w') as data_file:
		json.dump(cp_map, data_file, sort_keys=True, indent=4)

def _save_all():
	global _lc_map

	for cp_str in _lc_map:
		cp = int(cp_str)
		cp_map = _lc_map[cp_str]

		_save_cp_map(cp, cp_map)

def _initialize():
	_load_all()

	_save_all()

def get_data(cp, wcet):
	global _lc_map

	cp_str = str(cp)
	wcet_str = str(wcet)

	if cp_str not in _lc_map:
		return None

	if wcet_str not in _lc_map[cp_str]['wcets']:
		return None;

	return _lc_map[cp_str]['wcets'][wcet_str]

def exists(cp, wcet):
	return get_data(cp, wcet) is not None

def get(cp, wcet):
	global _lc_map

	data = get_data(cp, wcet)

	if data is None:
		return None

	return data['loops']

def set(cp, wcet, loops, **args):
	global _lc_map

	cp_str = str(cp)
	wcet_str = str(wcet)

	if cp_str not in _lc_map:
		sys.stderr.write("Invalid CP: %d\n", cp)
		return

	_lc_map[cp_str]['wcets'][wcet_str] =  {
		'cp': cp,
		'wcet': wcet,
		'loops': loops,
		'cet_min': 0 if 'cet_min' not in args else args['cet_min'],
		'cet_max': 0 if 'cet_max' not in args else args['cet_max'],
		'test_total': 0 if 'test_total' not in args else args['test_total'],
		'failed_total': 0 if 'failed_total' not in args else args['failed_total']}

	_save_cp_map(cp, _lc_map[cp_str])

def measure(cp, wcet):
	printlog(1, '== New loopcount measurement (cp=%d, wcet=%d) ==' % \
		(cp, wcet))

	wss = cp * 64
	period = wcet * 2
	duration = period # 1000 times, large enough 
	loop = wcet * 2 / cp

	scheduler = config.conf['lc_measure_scheduler']
	measure_loops = config.conf['lc_measure_count']

	printlog(1, "initial: cp=%d, wcet=%d, scheduler=%s, lc=%d, duration=%d" % \
		(cp, wcet, scheduler, loop, duration))

	total_count = 0
	failed_count = 0
	cet_min_all = 0
	cet_max_all = 0

	for i in range(1, measure_loops):
		ret, err_cet, count, cet_min, cet_max = \
			_measure_once(scheduler, cp, wss, loop, wcet, period, duration)

		total_count += 1

		if ret is False:
			failed_count += 1
			loop = int(wcet * loop / err_cet / 1000)
			printlog(1, "Failed: CET=%fs, new loop count=%d" % (err_cet, loop))

		if total_count == 1:
			cet_min_all = cet_min
			cet_max_all = cet_max
		elif cet_min_all > cet_min:
			cet_min_all = cet_min
		elif cet_max_all < cet_max:
			cet_max_all = cet_max
		
	loops = loop

	printlog(1, "Verifying the loopcount=%d" % loops)

	results = verify(scheduler, cp, wss, loops, wcet, 
		period, config.conf['duration'])

	printlog(1, "Verification result={}".format(results))

	# update lc map
	set(cp, wcet, loops, 
		cet_max = cet_max_all,
		cet_min = cet_min_all,
		test_total = total_count,
		failed_total = failed_count)

	return loops
			
def _measure_once(scheduler, cp, wss, loop, wcet, period, duration):
        init_args = '%s %s' % (config.conf['init_shell'], scheduler)
        init_proc = subprocess.Popen(init_args, shell=True)
        init_proc.wait()

	main_args = '%s -C %d -S %d -l %d -t %d %d %d' % \
		(config.conf['lc_measure_app'], cp, wss, loop, wcet, period, duration)

	main_proc = subprocess.Popen(main_args.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)

	count = 0
	cet_min = 0
	cet_max = 0
	err_cet = 0

	output, err = main_proc.communicate()

        for line in output.splitlines():
		printlog(0, line)

                if line.startswith('STRICT:'):
                        token = line.split()
                        if token[1] == 'FAILURE':
                                target = float(token[4])
                                cet = float(token[6])
                                err_cet = cet
                        elif token[1] == 'MEASURE':
                                target = float(token[2])
                                cet = float(token[4])
                                diff = float(token[6])

                                count += 1

                                if count == 1:
                                        cet_min = cet
                                        cet_max = cet
                                elif cet_min > cet:
                                        cet_min = cet
                                elif cet_max < cet:
                                        cet_max = cet
	
	main_proc.wait()

	if main_proc.returncode is 0:
		return True, err_cet, count, cet_min, cet_max
	
	return False, err_cet, count, cet_min, cet_max

def verify(scheduler, cp, wss, loop, wcet, period, duration):
	app = config.conf['main_app']
	params = '-w -C %d -S %d -l %d -r 1 -q 10 %d %d %d' % \
		(cp, wss, loop, wcet, period, duration)

	ti = taskset.TaskInfo(app, params, 0)

	prefix = 'lcm_C_%d_W_%d_P_%d_L_%d' % \
		(cp, wcet, period, loop)

	results = taskset.run(scheduler, [ti], prefix)

	return results

# initialize
_initialize()

