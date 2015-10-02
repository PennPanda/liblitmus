#!env python

import json
import os
import os.path
import atexit
import datetime
import sys

conf_file = 'config.json'

conf = None

log = None

def _initialize():
	global conf

	root_dir = os.path.abspath(os.path.dirname(__file__))

	if os.path.exists(root_dir + '/' + conf_file):
		with open(root_dir + '/' + conf_file, 'r') as data_file:
			conf = json.load(data_file)

	else:
		raise Exception("No configuration file found: %s/%s" % \
			(root_dir, conf_file))


	# basic setup

	# change to working directory
	os.chdir(conf['work_dir'])

	if not os.path.exists(conf['data_dir']):
		os.mkdir(conf['data_dir'])

	if not os.path.exists(conf['output_dir']):
		os.mkdir(conf['output_dir'])

	_setup_instance()

	_setup_global_log()


def _setup_instance():
	global conf

	dirs = []
	for entry in os.listdir(conf['output_dir']):
		if os.path.isdir('%s/%s' % (conf['output_dir'], entry)):
			dirs.append(entry)

	next_instance = len(dirs)

	# setup output_dir with instance number and date
	now = datetime.datetime.now()
	date_str = now.strftime('%Y%m%d_%H%M%S')
	outdir = '%s/%d-%s' % (conf['output_dir'], next_instance, date_str)

	conf['output_dir'] = outdir

	if not os.path.exists(conf['output_dir']):
		os.mkdir(conf['output_dir'])

def _setup_global_log():
	global conf, log

	logfilename = '%s/global_log.txt' % (conf['output_dir'])

	try:
		log = open(logfilename, 'w')

		atexit.register(_exit_function)
	except:
		log = None

	printlog(1, "Starting.....")

def _exit_function():
	global log

	if log is not None:
		log.close()

def printlog(dup, str):
	global log	

	outstr = '%s - %s\n' % (datetime.datetime.now(), str)

	if log is not None:
		log.write(outstr)

	if conf['print_output'] and dup == 1:
		sys.stdout.write(outstr)

# initialize
_initialize()

