#!/usr/bin/python

import os, os.path
import sys
import json
import subprocess
import math

import config
import jobstats

from config import printlog

'''
def load(target_dir):

    profiles = dict()

    for p in config.conf['taskset_profiles']:

        profiles[p] = {
            'schedulers': None,
            'utilizations': dict()
        }

        utils = profiles[p]['utilizations']

        pathname = '{}/result_{}.csv'.format(target_dir, p)

        schedulers = []

        with open(pathname, 'r') as infile:
            linecount = 0

            for line in infile:
                linecount += 1
                if linecount == 1:
                    continue

                token = line.strip().split(',')
                if len(token) == 3:
                    util = token[0].strip()
                    taskset = token[1].strip()
                    scheduler = token[2].strip()
                    
                    if util not in utils:
                        utils[util] = dict()
                
                    if scheduler not in utils[util]:
                        utils[util][scheduler] = dict()

                    if taskset not in utils[util][scheduler]:
                        utils[util][scheduler][taskset] = dict()

                    if scheduler not in schedulers:
                        schedulers.append(scheduler)

                elif len(token) == 16:
                    task = token[3].strip()
                    cp = token[4].strip()
                    wcet = token[5].strip()
                    period = token[6].strip()
                    #pid = token[7].strip()
                    ave_cet = token[8].strip()
                    min_cet = token[9].strip()
                    max_cet = token[10].strip()
                    dlmiss = token[11].strip()
                    dlmiss_all = token[12].strip()
                    ave_resp = token[13].strip()
                    min_resp = token[14].strip()
                    max_resp = token[15].strip()

                    utils[util][scheduler][taskset][task] = {
                        'index': int(task),
                        'cp': int(cp),
                        'wcet': int(wcet),
                        'period': int(period),
                        'ave_cet': int(ave_cet),
                        'min-cet': int(min_cet),
                        'max_cet': int(max_cet),
                        'dlmiss': int(dlmiss),
                        'dlmiss_all': int(dlmiss_all),
                        'ave_resp': int(ave_resp),
                        'min_resp': int(min_resp),
                        'max_resp': int(max_resp)
                    }   

        profiles[p]['schedulers'] = schedulers

    with open('profiles.json', 'w') as outfile:
        json.dump(profiles, outfile, sort_keys=True, indent=4)

    return profiles
'''
def load(target_dir):
    pathname = '{}/profiles.json'.format(target_dir)

    profiles = None

    with open(pathname, 'r') as infile:
        profiles = json.load(infile)

    return profiles;

def generate_schedulable(profiles):
    for p in profiles:

        out_filename = 'schedulable_{}.csv'.format(p)

        schedulers = profiles[p]['schedulers']
        utils = profiles[p]['utilizations']

        with open(out_filename, 'w') as outfile:
            outfile.write("{}\n".format(p))

            outfile.write("Utilization")
            for scheduler in schedulers:
                outfile.write(",{}".format(scheduler))
            outfile.write("\n")

            for ut in sorted(utils):
                util = utils[ut]

                tasksets = util['tasksets']

                schedulable = {s:0 for s in schedulers}
                complete_count = 0

                for tsi in sorted(tasksets):
                    taskset = tasksets[tsi]

                    if taskset['complete'] == 0:
                        continue

                    complete_count += 1

                    sched_check = {s:True for s in schedulers}
        
                    tasks = taskset['tasks']
                    for ti in tasks:
                        task = tasks[ti]

                        jobstats = task['jobstat']

                        for scheduler in jobstats:
                            js = jobstats[scheduler]
                            
                            if js['dlmiss_all'] != 0:
                                sched_check[scheduler] = False

                    for s in sched_check:
                        if sched_check[s]:
                            schedulable[s] += 1

                if complete_count == 0:
                    continue

                outfile.write("{}".format(ut))
                for scheduler in schedulers:
                    s_count = schedulable[scheduler]

                    ratio = float(s_count) / float(complete_count)

                    outfile.write(",{}".format(ratio))

                outfile.write("\n")

        # move the file to output_dir
        mv_args = 'mv -f {} {}'.format(out_filename, config.conf['output_dir'])
        mv_proc = subprocess.Popen(mv_args, shell=True)
        mv_proc.wait() 

def generate(profiles):

    generate_schedulable(profiles)

 
def find_target_dir(index):
    dir = config.conf['output_base_dir']

    subdir = None

    for entry in os.listdir(dir):
        if os.path.isdir('{}/{}'.format(dir, entry)) and \
            entry.startswith('{}-'.format(index)):
            subdir = entry
            break

    if subdir is None:
        return None

    return '{}/{}'.format(dir, subdir)

def main(argv):
    if len(argv) < 2:
        print "Usage: analyze.py {output_index}"
        sys.exit(0)

    target_dir = find_target_dir(argv[1])        
        
    if target_dir is None:
        print "No output directory found with index={}".format(argv[1])
        sys.exit(0)

    profiles = load(target_dir)

    generate(profiles)

if __name__ == "__main__":
    main(sys.argv)

