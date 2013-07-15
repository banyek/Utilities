Utilities
=========

Everday utilities for sysadmin stuff. Mostly for MySQL. 

* check_mysql_connections.sh 
 	- can run on any server, and filters the netcat output to check where is connected with mysql
* checkconn.pl
  - queries the information_schema.processlist table, to show who is connected to database
* checkfrag.pl 
  - queries the information_schema.tables table, compares the table sizes of the sizes used on disk
