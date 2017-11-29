Utilities
=========

Everday utilities for sysadmin stuff. Mostly for MySQL. 

* check_mysql_connections.sh 
 	- can run on any server, and filters the netcat output to check where is connected with mysql
* checkconn.pl
  - queries the information_schema.processlist table, to show who is connected to database
* checkfrag.pl 
  - queries the information_schema.tables table, compares the table sizes of the sizes used on disk
* monitor_space
  - Monitors space changes on mysql server
	- monitor_space_collector.pl - collects data about table sizes
	- monitor_space_qt.pl - Query tool for monitor space
* binlog_extractor.awk
	- You have to give it a GTID and it will return the next position from an SQL dump of MySQL binlog
* rds_node_selector.sh
    - fancy menu based terminal tool for connecting your rds instances. It queries the aws api for your hosts. When you use
      the --iddqd switch it can connect to writer nodes, if not, just the readers are available (if an aurora cluster has only 1
      node it could be writed as well. You need configured awscli, .my.cnf and dialog installed
