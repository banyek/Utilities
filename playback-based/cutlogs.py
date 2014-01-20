#!/usr/bin/python

import re

logfile = open('bigger','r')

boundary = re.compile('^# Time:')
entitydata = re.compile('^# Thread_id')

readbuffer = ''
db = ''
for line in logfile:
	if boundary.match(line):
		if db != '':
			readbuffer.rstrip('\n')
			outfile = open(db + '_slow.log','a')
			outfile.write(readbuffer)
			readbuffer = ''
	if entitydata.match(line):
		data = line.split(' ')
		db = data[5]
	readbuffer = readbuffer + line


