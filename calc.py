#!/usr/bin/env python
import math
import sys

class Event:
	def __init__(self, task, id, job, job_no, type, time):
		self.task = task
		self.id = id
		self.job = job
		self.jobno = job_no
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

			event = Event(task, id, job, job_no, type, time)

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
			sys.stderr.write("drop: {}\n".format(ajob))
			dellist.append(job)

		elif 'switch_to' not in ajob or 'switch_away' not in ajob:
			sys.stderr.write("drop: {}\n".format(ajob))
			dellist.append(job)

	for job in dellist:
		del jobs[job]

	return jobs

def calculate(jobs, deadline, pid):
	joblist = {}

	for job in jobs:
		ajob = jobs[job]

		sto = ajob['switch_to']
		saway = ajob['switch_away']

		task_id = sto.task

		if task_id not in joblist:
			joblist[task_id] = {
				'cet': [],
				'wcet': 0,
				'mcet': 1000000000000,
				'missed': 0,
				'avg': 0,
				'alldata': {}
				}

		acet = saway.time - sto.time
		joblist[task_id]['cet'].append(acet)
		joblist[task_id]['alldata'][saway.jobno] = {
			'job': sto.job,
			'cet': acet}

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

	if len(sys.argv) < 3 or len(sys.argv) > 4:
		print "Usage: ./calc.py {wcet} {pid} {file}"
		print "       ./calc.py {wcet} {file}"
		sys.exit(0)

	deadline = int(sys.argv[1]) * 1000000 # ms to ns

	if len(sys.argv) == 3:
		filename = sys.argv[2]
		pid = -1
	else:
		filename = sys.argv[3]
		pid = int(sys.argv[2])

	jobs = read(filename)

	filterout(jobs)


	joblist = calculate(jobs, deadline, pid)

	for job, stat in joblist.iteritems():
		if pid <=0 or pid == job:
			for key in sorted(stat['alldata']):
				sys.stderr.write("task: {} job: {} cet: {}\n" \
					.format(job, 
					stat['alldata'][key]['job'],
					stat['alldata'][key]['cet']))

			print "task %d wcet %d avg %d min %d missed %d" % \
				(job, stat['wcet'], 
				stat['avg'], stat['mcet'], 
				stat['missed'])
		
if __name__ == "__main__":
	main()

