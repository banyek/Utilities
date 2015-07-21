#!/usr/bin/perl

use DBI;
use Config::Simple;     # read .my.cnf file
use Getopt::Std;        # parse command line arguments
use Term::ReadKey;      # Read password in safe
use File::Temp;

# This script reads information_schema.tables from a source server and insert into dbinfo.table_sizes in a destination server for historical purposes.

# Load credentials from ~/.my.cnf if exists ([client] section)
$configfile = $ENV{"HOME"}."/.my.cnf";
if ( -e $configfile){
    $tempconfig = File::Temp->new;
    open(CONFIG,"<", "$configfile");
    open(TMPCONF,">","$tempconfig");
    chmod 0600, $tempconfig;
    while(<CONFIG>) {
        if ($_ !~ /^!/){
            print TMPCONF $_;
        }
    }
    close(CONFIG);
    close(TMPCONF);
    $config = new Config::Simple(filename=>$tempconfig);
    unlink tempconfig;
    $user = $config->param("client.user"), "\n";
    $password = $config->param("client.password"), "\n";
    # Don't overwrite host argument with .my.cnf contents
    #$host = $config->param("client.host"), "\n";
}
# Dealing with command line variables
getopts('hu:p:s:d:');

# show help screen
if ($opt_h){
  &usage;
}

# Set password to connect to database. If password is not provided, asks for it. Assuming user/password same in both source and destination servers.
if (defined $opt_p){
  $password=$opt_p;
}
elsif ($password eq '') {
  &getPassword;
}

# Set user to connect to database. If it wasn't provided here or in ~/.my.cnf defaults to 'root'. Assuming user/password same in both source and destination servers.
if (defined $opt_u){
  $user=$opt_u;
} elsif ($user eq '') {
  $user="root";
}

# Set host to read from. If it wasn't provided here or in ~/.my.cnf defaults to local IP
if (defined $opt_s){
  $source=$opt_s;
} elsif ($source eq '') {
  # Since this string will show in the output table, you might want to change the string below to an explicit default server name for clearer output
  $source="127.0.0.1"
}

# Set host to write to. If it wasn't provided here or in ~/.my.cnf defaults to local IP
if (defined $opt_d){
  $destination=$opt_d;
} elsif ($destination eq '') {
  $destination="127.0.0.1"
}

# Reads password form prompt
sub getPassword {
print "Password: ";
  ReadMode('noecho');
  $password = ReadLine(0);
  ReadMode('normal');
  chomp($password);
  print "\n";
}

# Shows help
sub usage {
  print "Usage: ./monitor_space.pl [ -h ] [ -u user ] [ -p password ] \n";
  print " -h                 this help screen\n";
  print " -u username        username with connect to mysql. Defaults 'root'\n";
  print " -p password        password with connect to mysql. If not provided,asks for it.\n";
  print " -s hostname        source hostname to get table sizes from. If not provided, defaults to local IP.\n";
  print " -d hostname        destination hostname to write history to. If not provided, defaults to local IP.\n";
  print "\n";
  exit 0;
}

# Connect to database
$dbh = DBI->connect("dbi:mysql:information_schema;host=$source",$user,$password);
# Get current date from db
$currentdate = $dbh->selectrow_array('SELECT NOW()');

# Select for table sizes (display per Megabytes)
$sql_table_sizes = "SELECT 
       table_schema,
       table_name,
       table_rows,
       CONCAT(ROUND(data_length / ( 1024 * 1024 ), 2))                    DATA,
       CONCAT(ROUND(index_length / ( 1024 * 1024 ), 2))                   idx,
       CONCAT(ROUND(( data_length + index_length ) / ( 1024 * 1024 ), 2)) total_size,
       create_time,
       update_time,
       check_time
       FROM information_schema.TABLES
       where
            table_schema not in ('information_schema', 'performance_schema', 'mysql', 'percona_index_stats')
       ORDER  BY data_length + index_length DESC;";
$sth = $dbh->prepare($sql_table_sizes);
$sth->execute;
# Fetch query results, inserts it into test.table_sizes
$dbh2 = DBI->connect("dbi:mysql:information_schema;host=$destination",$user,$password);
while (@row = $sth->fetchrow_array){
    $table_schema = $row[0];
    $table_name = $row[1];
    $table_rows = $row[2];
    $data_size = $row[3];
    $index_size = $row[4];
    $total_size = $row[5];
    $create_time = $row[6];
    $update_time = $row[7];
    $check_time = $row[8];
    $sql_insert= "INSERT INTO dbinfo.table_sizes (date, hostname, table_schema, table_name, table_rows, data_size, index_size, total_size, create_time, update_time, check_time) VALUES ('$currentdate','$source','$table_schema','$table_name','$table_rows','$data_size','$index_size','$total_size','$create_time','$update_time','$check_time')";
    $isth=$dbh2->prepare($sql_insert);
    $isth->execute;
}
