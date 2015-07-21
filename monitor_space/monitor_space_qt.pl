#!/usr/bin/perl

# Monitor Space Query Tool
# Command-line tool to list all tables that have changed in sizes within a time period. This data must have been previously collected by monitor_space_collector.pl
# Limitation: output will be truncated if any hostname, db name, table name greater than 30 characters. This is a formatting choice just to beautify output, modify as required.

use DBI;                # Connect MySQL database, run queries
use Config::Simple;     # read .my.cnf file
use Getopt::Std;        # parse command line arguments
use Term::ReadKey;      # Read password in safe
use File::Temp;

# Location of the table containing historical data to retrieve. Assuming server is localhost or already defined in .my.cnf
$db=dbinfo;
$table=table_sizes;

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
    $host = $config->param("client.host"), "\n";
}

# Dealing with command line variables
getopts('hu:p:t:f:w:e');

# show help screen
if ($opt_h){
  &usage;
}

# Set password to connect to database. If password is not provided, asks for it.
if (defined $opt_p){
  $password=$opt_p;
}
elsif ($password eq '') {
  &getPassword;
}

# Set user to connect to database. If it wasn't provided here or in ~/.my.cnf defaults to 'root'
if (defined $opt_u){
  $user=$opt_u;
} elsif ($user eq '') {
  $user="root";
}
if ($host eq '') {
   $host="127.0.0.1"
}

# Get minimum time
if (defined $opt_f){
    $fromdate=$opt_f;
}
# Get maximum time
if (defined $opt_t){
    $todate=$opt_t;
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
  print "Usage: ./monitor_space_qt.pl [ -h ] [ -u user ] [ -p password ] \n";
  print " -h                 this help screen\n";
  print " -u username        username with connect to mysql. Defaults 'root'\n";
  print " -p password        password with connect to mysql. If not provided,asks for it.\n";
  print " -f date            from date (mysql date format)\n";
  print " -t date            to date (mysql date format\n";
  print " -w tablename       table to check\n";
  print " -e                 don't write headers (useful for sorting, and using output in pipeline)\n";
  print " When called without any options, script will show a list of all tables that have changed sizes since the very beginning of data collection.";
  print "\n";
  exit 0;
}


if ((defined $fromdate) and (defined $todate)){
    if (defined $opt_w) {
        $sql="SELECT date, hostname, table_schema, table_name, data_size, index_size, total_size FROM $db.$table WHERE table_name LIKE '$opt_w' AND `date` BETWEEN '$fromdate' AND '$todate' ORDER BY date";
    }
    else {
        $sql="SELECT hostname, table_schema, table_name, MAX(total_size) - MIN(total_size) AS size_changed FROM $db.$table WHERE `date` BETWEEN '$fromdate' AND '$todate' GROUP BY table_name HAVING size_changed > 0";
    }
}
elsif (defined $fromdate) {
    if (defined $opt_w){
        $sql="SELECT date, hostname, table_schema, table_name, data_size, index_size, total_size FROM $db.$table WHERE table_name LIKE '$opt_w' AND date > '$fromdate' ORDER BY date";
    }
    else {
        $sql="SELECT hostname, table_schema, table_name, MAX(total_size) - MIN(total_size) AS size_changed FROM $db.$table WHERE `date` > '$fromdate' GROUP BY table_name HAVING size_changed > 0";
    }
}
elsif (defined $todate) {
if (defined $opt_w){
        $sql="SELECT date, hostname, table_schema, table_name, data_size, index_size, total_size FROM $db.$table WHERE table_name LIKE '$opt_w' AND date < '$todate' ORDER BY date";
    }
    else {
        $sql="SELECT hostname, table_schema, table_name, MAX(total_size) - MIN(total_size) AS size_changed FROM $db.$table WHERE `date` < '$todate' GROUP BY table_name HAVING size_changed > 0";
    }
}
else {
    if (defined $opt_w){
        $sql="SELECT date, hostname, table_schema, table_name, data_size, index_size, total_size FROM $db.$table WHERE table_name LIKE '$opt_w' ORDER BY date";
    }
    else {
        $sql="SELECT hostname, table_schema, table_name, MAX(total_size) - MIN(total_size) AS size_changed FROM $db.$table GROUP BY table_name HAVING size_changed > 0";
    }
}

$dbh = DBI->connect("dbi:mysql:information_schema;host=$host",$user,$password);
$sth = $dbh->prepare($sql);
$sth -> execute or die "SQL error: $DBI::errstr\n";
if ( ! defined $opt_e){
  if (defined $opt_w){
    print "Date                  Hostname            Table schema                  Table name                       Data size  Index size  Total size\n==========================================================================================================================================\n";
  }
  else {
    print("Hostname            Table schema                  Table name                  Size changed\n==========================================================================================\n");
  }
}
while (@row = $sth->fetchrow_array) {
  if (defined $opt_w){
    printf("%-22s%-20s%-30s%-30s%12.2f%12.2f%12.2f\n",$row[0],$row[1],$row[2],$row[3],$row[4],$row[5],$row[6]);
  }
  else {
    printf("%-20s%-30s%-30s%10.2f\n",$row[0],$row[1],$row[2],$row[3]);
  }
}
