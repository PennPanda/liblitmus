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

	with open(pathname, 'r') as infile:
		profiles = json.load(infile)

	return profiles

def save(profiles):
    pathname = '{}/profiles.json'.format(config.conf['output_dir'])

    with open(pathname, 'w') as outfile:
        json.dump(profiles, outfile, sort_keys=True, indent=4)

def analyze(profiles, target_dir):
    for p in profiles:
        profile = profiles[p]

        out_filename = 'result_{}.csv'.format(p)

        with open(out_filename, 'w') as outfile:
            outfile.write("Utilization, TaskSet, Scheduler, ")
            outfile.write("Task, CP, WCET, PERIOD, Pid, ")
            outfile.write("AvgCET, MinCET, MaxCET, ")
            outfile.write("DLMISS(event), DLMISS(all), ")
            outfile.write("AvgResp, MinResp, MaxResp\n")

            utils = profile['utilizations']
            schedulers = profile['schedulers']
            duration = profile['duration']

            for ut in sorted(utils):
                util = utils[ut]

                tasksets = util['tasksets']

                for ti in sorted(tasksets):
                    taskset = tasksets[ti]

                    if taskset['complete'] != 1:
                        continue

                    tasks = taskset['tasks']

                    for scheduler in schedulers:
                        prefix = '{}#{}#{}#{}'.format(p, ut, ti, scheduler)
                        outfile.write("{}, {}, {}\n".format(ut, ti, scheduler))
                        analyze_one(tasks, prefix, target_dir, scheduler, duration, outfile)

        # move the file to output_dir
        mv_args = 'mv -f {} {}'.format(out_filename, config.conf['output_dir'])
        mv_proc = subprocess.Popen(mv_args, shell=True)
        mv_proc.wait() 

        # save new profiles.json
        save(profiles)        

def analyze_one(tasks, prefix, dir, scheduler, duration, outfile):
    printlog(1, "Analyze for {}".format(prefix))

    pathname = '{}/st-{}-0.bin'.format(dir, prefix)

    if not os.path.exists(pathname):
        return

    files = '{}/st-{}-?.bin'.format(dir, prefix)

    jobs_filename = '{}/jobstats_{}.txt'.format(
        config.conf['output_dir'], prefix)
    
    with open(jobs_filename, 'w') as jobsfile:
        task_stats = jobstats.generate(files, outfile=jobsfile)

    # map task id to index
    pids = sorted(task_stats.keys())

    printlog(1, "pids: {}".format(pids))
    for index in sorted(tasks):
        task = tasks[index]

        pid = pids[int(index)]
        js = task_stats[pid]

        if 'pid' not in task:
            task['pid'] = dict()

        if 'jobstat' not in task:
            task['jobstat'] = dict()

        task['pid'][scheduler] = pid
        task['jobstat'][scheduler] = {
            'ave_cet': js.ave_cet,
            'min_cet': js.min_cet,
            'max_cet': js.max_cet,
            'dlmiss': js.dlmiss,
            'ave_resp': js.ave_resp,
            'min_resp': js.min_resp,
            'max_resp': js.max_resp
        }

        all_jobs = int(math.ceil(duration * 1000 / task['period']))
        printlog(0, "all jobs: {}".format(all_jobs))

        dlmiss_all = all_jobs - js.job_count
        if dlmiss_all < 0 : 
            dlmiss_all = 0

        dlmiss_all += js.dlmiss
        js.dlmiss_all = dlmiss_all

        task['jobstat'][scheduler]['dlmiss_all'] = dlmiss_all

        outfile.write(",,,")
        outfile.write("{},{},{},{},{},".format(
            index, task['cp'], task['wcet'], task['period'], pid))
        outfile.write("{},{},{},".format(js.ave_cet, js.min_cet, js.max_cet))
        outfile.write("{},{},".format(js.dlmiss, dlmiss_all))
        outfile.write("{},{},{}\n".format(js.ave_resp, js.min_resp, js.max_resp))
  
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

	analyze(profiles, target_dir)

if __name__ == "__main__":
	main(sys.argv)

