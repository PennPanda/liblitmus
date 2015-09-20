#!/usr/bin/env python

import math
import sys

class Event:
	def __init__(self, task, id, job, type, time):
		self.task = task
		self.id = id
		self.job = job
		self.type = type
		self.time = time

	def __repr__(self):
		return '%d %d %s %s %d' % \
			(self.task, self.id, self.job, self.type, self.time)

def read(filename):
	jobs = dict()

	fd = open(filename, 'r')

	task = 0
	id = 0
	job = ''
	type = ''
	time = 0

	for line in fd:
		token = line.split(' ')
		if token[0] == 'Event':
			id = int(token[2])
		elif token[0] == 'Job:':
			job = token[1].strip()
			task_id = job.split('.')
			task = int(task_id[0])
			job_no = int(task_id[1])
		elif token[0] == 'Type:':
			type = token[1].strip()
		elif token[0] == 'Time:':
			time = int(token[1])

			if job_no < 3:
				continue

			event = Event(task, id, job, type, time)

			if job not in jobs:
				jobs[job] = dict()
			
			jobs[job][type] = event
			
			task = 0
			id = 0
			job = ''
			type = ''
			time = 0

	return jobs

def filterout(jobs):
	dellist = []

	for job in jobs:
		ajob = jobs[job]

		if len(ajob) < 3:
			sys.stderr.write("drop: {}".format(ajob))
			dellist.append(job)

		elif 'switch_to' not in ajob or 'switch_away' not in ajob:
			sys.stderr.write("drop: {}".format(ajob))
			dellist.append(job)

	for job in dellist:
		del jobs[job]

	return jobs

def calculate(jobs, deadline):
	joblist = {}

	for job in jobs:
		ajob = jobs[job]

		task_id = ajob['switch_to'].task

		if task_id not in joblist:
			joblist[task_id] = {
				'cet': [],
				'wcet': 0,
				'mcet': 1000000000000,
				'missed': 0,
				'avg': 0}

		acet = ajob['switch_away'].time - ajob['switch_to'].time
		joblist[task_id]['cet'].append(acet)

		if acet > deadline:
			joblist[task_id]['missed'] += 1

		if acet > joblist[task_id]['wcet']:
			joblist[task_id]['wcet'] = acet
		if acet < joblist[task_id]['mcet']:
			joblist[task_id]['mcet'] = acet

	for task_id in joblist:
		joblist[task_id]['avg'] = math.fsum(joblist[task_id]['cet']) / len(joblist[task_id]['cet'])

	return joblist
	

def main():
	deadline = int(sys.argv[1]) * 1000000 # ms to ns
	filename = sys.argv[2]

	jobs = read(filename)

	filterout(jobs)


	joblist = calculate(jobs, deadline)

	for job, stat in joblist.iteritems():
		print "task %d wcet %d avg %d min %d missed %d" % (job, stat['wcet'], stat['avg'], stat['mcet'], stat['missed'])
		
if __name__ == "__main__":
	main()

