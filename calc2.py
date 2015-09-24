#!/usr/bin/env python
import math
import sys
import subprocess

class Record:
	def __init__(self, task, job, period, response, execution, dlmiss, lateness, tardiness, forced):
		self.task = task
		self.job = job
		self.period = period
		self.response = response
		self.execution = execution
		self.dlmiss = dlmiss
		self.lateness = lateness
		self.tardiness = tardiness
		self.forced = forced;

	def __repr__(self):
		return '%6d %5d %10d %10d %10d %2d %10d %10d %2d' % \
			(self.task, self.job, self.period, self.response,
			self.execution, self.dlmiss, self.lateness, self.tardiness,
			self.forced)

def read(filename):
	jobs = dict()

	fd = open(filename, 'r')

	for line in fd:
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

		record = Record(task, job, period, response, execution, dlmiss, 
			lateness, tardiness, forced)	

		jobs[job] = record
	return jobs

def calculate(jobs):
	sum = 0
	count = 0
	min = 0
	max = 0
	dlmiss = 0

	for job in sorted(jobs):
		ajob = jobs[job]

		# skip job number below 4
		if ajob.job < 4:
			continue

		# skip forced
		if ajob.forced == 1:
			continue

		sum += ajob.execution

		if count == 0:
			min = ajob.execution
			max = ajob.execution
		elif ajob.execution < min:
			min = ajob.execution
		elif ajob.execution > max:
			max = ajob.execution

		if ajob.dlmiss == 1:
			dlmiss += 1

		count += 1

	if count > 0:
		avg = sum / count
	else:
		avg = 0

	return avg, min, max, dlmiss
	

def main():

	if len(sys.argv) < 2:
		print "Usage: ./calc2.py {file}"
		sys.exit(0)


	jobs = read(sys.argv[1])

	avg, min, max, dlmiss = calculate(jobs)

	print "%d,%d,%d,%d" % (avg, min, max, dlmiss)
	
	
if __name__ == "__main__":
	main()

