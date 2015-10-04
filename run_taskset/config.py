#!env python

import json
import os
import os.path
import atexit
import datetime
import sys

conf_file = 'config.json'

#conf is set as default values

conf = {
    # assume parent is the liblitmus folder
    'work_dir': '..',

    'data_dir': 'taskset_data',
    'output_dir': 'taskset_output',
    'print_output': True,

    'min_cp': 1,
    'max_cp': 16,

    'duration': 60,

    'schedulers': ['GSN-FPCA', 'GSN-NPFPCA', 'GSN-FP'],

    'main_app': './ca_spin',
    'pollute_app': './ca_thrash',

    'use_pollute_task': False,

    'init_shell': './init.sh',
    'release_ts': './release_ts',
    'st_trace': 'st_trace',
    'st_job_stats': 'st_job_stats',

    'do_analysis': False,

    'taskset_dir': '',
    'taskset_profiles': [],
    'max_tasksets': 999,

    'lc_measure_app': './ca_spin_hard',
    'lc_measure_scheduler': 'GSN-FPCA',
    'lc_measure_output': 'loopcounts',
    'lc_measure_count': 20
}

log = None

def _initialize():
    global conf

    root_dir = os.path.abspath(os.path.dirname(__file__))
    pathname = "{}/{}".format(root_dir, conf_file)

    if os.path.exists(pathname):
        with open(pathname, 'r') as data_file:
            conf.update(json.load(data_file))

    else:
        with open(pathname, 'w') as data_file:
             json.dump(conf, data_file, indent=4)

        sys.stderr.write("Default configuration file is just saved. Please modify configuration for your environment settings.\n")
        sys.exit(0)

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

    # copy original to base_dir
    conf['output_base_dir'] = conf['output_dir']
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

