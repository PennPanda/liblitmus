#!env python

import sys
import math
import subprocess

import config
from config import printlog

class JobRecord:
    def __init__(self, task, job, period, response, execution, dlmiss, lateness, tardiness, forced):
        self.task = task
        self.job = job
        self.period = period
        self.response = response
        self.execution = execution
        self.dlmiss = dlmiss
        self.lateness = lateness
        self.tardiness = tardiness
        self.forced = forced

    def __repr__(self):
        return '%6d %5d %10d %10d %10d %2d %10d %10d %2d' % \
            (self.task, 
            self.job, 
            self.period, 
            self.response,
            self.execution,
            self.dlmiss,
            self.lateness,
            self.tardiness,
            self.forced)

class TaskRecord:
    def __init__(self, task):
        self.task = task
        self.jobs = dict()
	self.excl_jobs = dict()

        self.min_cet = 0
        self.max_cet = 0
        self.ave_cet = 0

        self.max_jobno = 0
        self.dlmiss = 0
        self.dlmiss_all = 0

        self.min_resp = 0
        self.max_resp = 0
        self.ave_resp = 0

        self._cet_sum = 0
        self._resp_sum = 0

        self.job_count = 0
        
    def __repr__(self):
        head = 'TaskRecord({})['.format(self.task)
        tail = ']'

        cet_str = 'CET(min={}, max={}, avg={})' \
            .format(self.min_cet, self.max_cet, self.ave_cet)
        resp_str = 'RESP(min={}, max={}, avg={})' \
            .format(self.min_resp, self.max_resp, self.ave_resp)
        other_str = 'dlmiss={}'.format(self.dlmiss)
        
        jobs_str = []
        for job in sorted(self.jobs):
            jobs_str.append('[{}]'.format(self.jobs[job]))

        all_str = '{}{}, {}, {},\n{}{}' \
            .format(head, cet_str, resp_str, other_str, jobs_str.join('\n'), tail)
        return all_str

    def addJobRecord(self, job):
        self.job_count += 1

        if job.job in self.jobs:
            printlog(1, "duplicated job found: {}".format(job))
            return

        if job.job < 4:
            printlog(0, "excluded (jobid < 4): {}".format(job))
            self.excl_jobs[job.job] = job
            return

        if job.forced == 1:
            printlog(0, "excluded (forced = 1): {}".format(job))
            self.excl_jobs[job.job] = job
            return

    	if job.response == 0:
            printlog(0, "excluded (resp=0): {}".format(job))
            self.excl_jobs[job.job] = job

            if job.dlmiss != 0:
                self.dlmiss += 1
            return

        if job.execution == 0:
            printlog(0, "excluded (cet=0): {}".format(job))
            self.excl_jobs[job.job] = job
    
            if job.dlmiss != 0:
                self.dlmiss += 1
            return
    
        self.jobs[job.job] = job
    
        if len(self.jobs) <= 1:
            self.min_cet = job.execution
            self.max_cet = job.execution
            self.min_resp = job.response
            self.max_resp = job.response
        else:
            if job.execution < self.min_cet:
                self.min_cet = job.execution
            elif job.execution > self.max_cet:
                self.max_cet = job.execution
    
            if job.response < self.min_resp:
                self.min_resp = job.response
            elif job.response > self.max_resp:
                self.max_resp = job.response

        printlog(0, "job: {}".format(job))
        printlog(0, "mincet:{}, maxcet:{}, minresp:{}, maxresp:{}".format(
            self.min_cet, self.max_cet, self.min_resp, self.max_resp))
    
        if job.dlmiss != 0:
            self.dlmiss += 1
    
        if job.job > self.max_jobno:
            self.max_jobno = job.job
    
        self._cet_sum += job.execution
        self.ave_cet = self._cet_sum / len(self.jobs)
    
        self._resp_sum += job.response
        self.ave_resp = self._resp_sum / len(self.jobs)

def generate(filenames, **args):
    tasks = dict()

    opt_pid = '-p {}'.format(args['pid']) \
        if 'pid' in args else ''

    js_args = '{} {} {}'.format( \
        config.conf['st_job_stats'],
        opt_pid, 
        filenames)

    js_proc = subprocess.Popen(js_args, shell=True,
        stdout=subprocess.PIPE, stderr=config.log)

    output, err = js_proc.communicate()

    printlog(0, js_args)

    if 'outfile' in args:
        outfile = args['outfile']

        outfile.write(output)
    else:
        printlog(0, output)

    for line in output.splitlines():
        if line[0] == '#':
            continue

        token = line.split(',')
        if len(token) != 9:
            continue

        task = int(token[0].strip())
        job = int(token[1].strip())
        period = int(token[2].strip())
        response = int(token[3].strip())
        execution = int(token[4].strip())
        dlmiss = int(token[5].strip())
        lateness = int(token[6].strip())
        tardiness = int(token[7].strip())
        forced = int(token[8].strip())

        record = JobRecord(task, job, period, response, execution, dlmiss,
            lateness, tardiness, forced)

        if task not in tasks:
            tasks[task] = TaskRecord(task)

        tasks[task].addJobRecord(record)

    return tasks


