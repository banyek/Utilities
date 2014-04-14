#!/usr/bin/perl

# Monitor Space Query Tool
# Tool for query mysql table sizes change what is provided by montior_space.pl

use DBI;                # Connect MySQL database, run queries
use Config::Simple;     # read .my.cnf file
use Getopt::Std;        # parse command line arguments
use Term::ReadKey;      # Read password in safe
use File::Temp;

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
  print "Usage: ./msqt.pl [ -h ] [ -u user ] [ -p password ] \n";
  print " -h                 this help screen\n";
  print " -u username        username with connect to mysql. Defaults 'root'\n";
  print " -p password        password with connect to mysql. If not provided,asks for it.\n";
  print " -f date            from date (mysql date format)\n";
  print " -t date            to date (mysql date format\n";
  print " -w tablename       table to check\n";
  print " -e                 don't write headers (useful for sorting, and using output in pipeline)\n";
  print "\n";
  exit 0;
}


if ((defined $fromdate) and (defined $todate)){
    if (defined $opt_w) {
        $sql="SELECT date, tablename, datasize, indexsize, totalsize FROM test.table_sizes WHERE tablename LIKE '$opt_w' AND `date` BETWEEN '$fromdate' AND '$todate' ORDER BY date";
    }
    else {
        $sql="SELECT tablename, MAX(totalsize) - MIN(totalsize) AS size_changed FROM test.table_sizes WHERE `date` BETWEEN '$fromdate' AND '$todate' GROUP BY tablename HAVING size_changed > 0";
    }
}
elsif (defined $fromdate) {
    if (defined $opt_w){
        $sql="SELECT date, tablename, datasize, indexsize, totalsize FROM test.table_sizes WHERE tablename LIKE '$opt_w' AND date > '$fromdate' ORDER BY date";
    }
    else {
        $sql="SELECT tablename, MAX(totalsize) - MIN(totalsize) AS size_changed FROM test.table_sizes WHERE `date` > '$fromdate' GROUP BY tablename HAVING size_changed > 0";
    }
}
elsif (defined $todate) {
if (defined $opt_w){
        $sql="SELECT date, tablename, datasize, indexsize, totalsize FROM test.table_sizes WHERE tablename LIKE '$opt_w' AND date < '$todate' ORDER BY date";
    }
    else {
        $sql="SELECT tablename, MAX(totalsize) - MIN(totalsize) AS size_changed FROM test.table_sizes WHERE `date` < '$todate' GROUP BY tablename HAVING size_changed > 0";
    }
}
else {
    if (defined $opt_w){
        $sql="SELECT date, tablename, datasize, indexsize, totalsize FROM test.table_sizes WHERE tablename LIKE '$opt_w' ORDER BY date";
    }
    else {
        $sql="SELECT tablename, MAX(totalsize) - MIN(totalsize) AS size_changed FROM test.table_sizes GROUP BY tablename HAVING size_changed > 0";
    }
}

$dbh = DBI->connect('dbi:mysql:information_schema',$user,$password);
$sth = $dbh->prepare($sql);
$sth -> execute or die "SQL error: $DBI::errstr\n";
if ( ! defined $opt_e){
  if (defined $opt_w){
    print "Date                  Table name                                           Data size  Index size  Total size\n============================================================================================================\n";
  }
  else {
    print("Table name                                      Size changed\n============================================================\n");
  }
}
while (@row = $sth->fetchrow_array) {
  if (defined $opt_w){
    printf("%-22s%-50s%12.2f%12.2f%12.2f\n",$row[0],$row[1],$row[2],$row[3],$row[4]);
  }
  else {
    printf("%-50s%10.2f\n",$row[0],$row[1]);
  }
}
