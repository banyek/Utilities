#
# gAWK script to extract end_log_pos from MySQL binrary log for point in time recovery
# 
# It takes 2 variables: 
#	last_gtid which is mandatory: this holds the GTID what the server last applied
# 	print_lines which print lines for this transaction
#
#
# EXAMPLE USAGE: awk -f binlog_extractor.awk -v last_gtid="e907792a-8417-11e3-a037-b4b52f51dbf8:23557937678" mysql-bin.sql
BEGIN{ 
# Parameter checking. If last GTID is not given, program exists, else it will initialize
	if(last_gtid=="") { 
		print "last_gtid must be set!"; 
		exit 
	} else { 
		gtid_found = 0; 
		log_remain = 4; 
	}
}

# When we found the given GTID we iterate to the last line of it
$0 ~ last_gtid { gtid_found = 1; }
gtid_found == 1 && print_lines == 1 { print $0 }
gtid_found == 1 && /^\# at/ { log_remain-- }
log_remain == 0 { exit }


END {

	if (print_lines == 1) {
		exit
	} else {
		print $3 
	}
}
