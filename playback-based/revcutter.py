#!/usr/bin/python
#
# (c) Balazs Pocze - Kinja
#

import re
import time
import datetime

logfile = open('mysql56_mastertest.log_reverse','r')
outfile = open('threadclosed_reverse.log','a')

boundary = re.compile('^# Time:')
threadreg = re.compile('^# Thread_id')
closedreg = re.compile('^# administrator command: Quit;')
timestampreg = re.compile("^SET timestamp=")
#trxidreg = re.compile("^# InnoDB_trx_id:")

linenumber = 0
closedthreads = set()
logentry = ""
for line in logfile:
	linenumber = linenumber + 1
	logentry = logentry + line
	if threadreg.match(line):
		data = line.split(' ')
		threadid = data[2]
	if timestampreg.match(line):
		data = line.split('=')
		timestamp = data[1].rstrip(';\n')
#	if trxidreg.match(line):
#		data = line.split(': ')
#		trxid = data[1]
	if boundary.match(line):
		if closedreg.match(logentry):
			closedthreads.add(threadid)
		elif threadid in closedthreads:
			pass
		else:
			convts = datetime.datetime.fromtimestamp(float(timestamp))
			convts.strftime('%y%m%d %H:%M:%S')
			closeevent="""# administrator command: Quit;
SET timestamp=%s;
# No InnoDB statistics available for this query
# Filesort: No  Filesort_on_disk: No  Merge_passes: 0
# QC_Hit: No  Full_scan: No  Full_join: No  Tmp_table: No  Tmp_table_on_disk: No
# Bytes_sent: 0  Tmp_tables: 0  Tmp_disk_tables: 0  Tmp_table_sizes: 0
# Query_time: 0.000000  Lock_time: 0.000000  Rows_sent: 0  Rows_examined: 0  Rows_affected: 0  Rows_read: 0
# Thread_id: %s  Schema: kinja Last_errno: 0  Killed: 0
# User@Host: percona[percona] @ localhost []
# Time: %s
""" % (timestamp, threadid, convts.strftime('%y%m%d %H:%M:%S'))
			outfile.write(closeevent)
		outfile.write(logentry)
		logentry = ""
