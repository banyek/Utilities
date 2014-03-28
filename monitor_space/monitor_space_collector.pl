#!/usr/bin/perl

use DBI;
use Config::Simple;     # read .my.cnf file
use Getopt::Std;        # parse command line arguments
use Term::ReadKey;      # Read password in safe
use File::Temp;

# Load credentials from ~/.my.cnf if exists ([client] section)
# NOTE: THIS IS NOT THE SAFEST WAY!
# The problem is, that the rpm available Perl-Config utilities failing when enountering lines starting with '!'
# To avoid this I create a tempfile, copies over the contents of local my.cnf without the inlude lines, parse that config,
# and then remove the temporary file.
# That means during the config parse they will appear a file for a short period with credentials. I don't encourage it using
# at public available places. You can use Config::MySQL,
#  or patching Config::Simple (see more at https://rt.cpan.org/Public/Bug/Display.html?id=94177)
#

$configfile = $ENV{"HOME"}."/.my.cnf";
if ( -e $configfile){
    $tempconfig = File::Temp->new;
    open(CONFIG,"<", "$configfile");
    open(TMPCONF,">","$tempconfig");
    while(<CONFIG>) {
        if ($_ !~ /^!/){
            print TMPCONF $_;
        }
    }
    close(CONFIG);
    print $tempconfig;
    close(TMPCONF);
    $config = new Config::Simple(filename=>$tempconfig);
    unlink tempconfig;
    $user = $config->param("client.user"), "\n";
    $password = $config->param("client.password"), "\n";
}
# Dealing with command line variables
getopts('hu:p:');

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
  print "\n";
  exit 0;
}

# Connect to database
$dbh = DBI->connect('dbi:mysql:information_schema',$user,$password);
# Get current date from db
$currentdate = $dbh->selectrow_array('SELECT NOW()');

# Select for table sizes (display per Megabytes)
$sql_table_sizes = "SELECT CONCAT(table_schema, '.', table_name) as tablename,
       CONCAT(ROUND(data_length / ( 1024 * 1024 ), 2))                    DATA,
       CONCAT(ROUND(index_length / ( 1024 * 1024 ), 2))                   idx,
       CONCAT(ROUND(( data_length + index_length ) / ( 1024 * 1024 ), 2)) total_size
       FROM   information_schema.TABLES
       where
            table_schema not in ('information_schema', 'performance_schema', 'mysql', 'percona_index_stats')
       ORDER  BY data_length + index_length DESC;";
$sth = $dbh->prepare($sql_table_sizes);
$sth->execute;
# Fetch query results, inserts it into test.table_sizes
while (@row = $sth->fetchrow_array){
    $tablename = $row[0];
    $tablesize = $row[1];
    $indexsize = $row[2];
    $totalsize = $row[3];
    $sql_insert= "INSERT INTO test.table_sizes (date,tablename,datasize,indexsize,totalsize) VALUES ('$currentdate','$tablename','$tablesize','$indexsize','$totalsize')";
    $isth=$dbh->prepare($sql_insert);
    $isth->execute;
}
