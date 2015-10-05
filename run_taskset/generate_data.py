#!/usr/bin/python

import os, os.path
import sys
import json
import subprocess
import math

import config
import jobstats

from config import printlog

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

def get_average(iteratable):
    sum = 0.0

    for i in iteratable:
        sum += i

    return sum / float(len(iteratable))

def generate_response_time(profiles):
    for p in profiles:

        avg_filename = 'avg-resp_{}.csv'.format(p)
        wst_filename = 'wst-resp_{}.csv'.format(p)

        schedulers = profiles[p]['schedulers']
        utils = profiles[p]['utilizations']

        with open(avg_filename, 'w') as avgfile, open(wst_filename, 'w') as wstfile:
            avgfile.write("{}\n".format(p))
            wstfile.write("{}\n".format(p))


            avgfile.write("Utilization")
            wstfile.write("Utilization")
            for scheduler in schedulers:
                avgfile.write(",{}".format(scheduler))
                wstfile.write(",{}".format(scheduler))
            avgfile.write("\n")
            wstfile.write("\n")

            for ut in sorted(utils):
                util = utils[ut]

                tasksets = util['tasksets']

                avg_resp_all = {s:[] for s in schedulers}
                wst_resp_all = {s:[] for s in schedulers}
                complete_count = 0

                for tsi in sorted(tasksets):
                    taskset = tasksets[tsi]

                    if taskset['complete'] == 0:
                        continue

                    complete_count += 1

                    norm_max_resp = {s:[] for s in schedulers}
        
                    tasks = taskset['tasks']
                    for ti in tasks:
                        task = tasks[ti]

                        jobstats = task['jobstat']

                        for scheduler in jobstats:
                            js = jobstats[scheduler]

                            if js['max_resp'] > 0:
                                aval = float(js['max_resp']) / float(task['period'])
                                norm_max_resp[scheduler].append(aval)
                            
                    for scheduler in schedulers:
                        wst = max(norm_max_resp[scheduler])
                        avg = get_average(norm_max_resp[scheduler])

                        avg_resp_all[scheduler].append(avg)
                        wst_resp_all[scheduler].append(wst)

                if complete_count == 0:
                    continue

                avgfile.write("{}".format(ut))
                wstfile.write("{}".format(ut))
                for scheduler in schedulers:
                    final_avg_resp = get_average(avg_resp_all[scheduler])
                    final_wst_resp = get_average(wst_resp_all[scheduler])

                    avgfile.write(",{}".format(final_avg_resp))
                    wstfile.write(",{}".format(final_wst_resp))

                avgfile.write("\n")
                wstfile.write("\n")

        # move the file to output_dir
        mv_args = 'mv -f {} {}'.format(avg_filename, config.conf['output_dir'])
        mv_proc = subprocess.Popen(mv_args, shell=True)
        mv_proc.wait() 

        mv_args = 'mv -f {} {}'.format(wst_filename, config.conf['output_dir'])
        mv_proc = subprocess.Popen(mv_args, shell=True)
        mv_proc.wait() 

def generate(profiles):

    generate_schedulable(profiles)

    generate_response_time(profiles)

 
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

