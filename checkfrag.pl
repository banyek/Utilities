#!/usr/bin/perl
#
# CheckFragmentation.pl
#
# Checks the table sizes in the database and shows the actual file size. If the difference is big, you can consider
# an OPTIMIZE TABLE command.
#

# Modules used, DBI, ReadKey, Getopt::Std, Config::Simple
#
use DBI;
use Term::ReadKey;
use Getopt::Std;
use Config::Simple;

# Load credentials from ~/.my.cnf if exists ([client] section)
$configfile = $ENV{"HOME"}."/.my.cnf";
if ( -e $configfile){
    $config = new Config::Simple(filename=>$configfile);
    $user = $config->param("client.user"), "\n";
    $password = $config->param("client.password"), "\n";
}

# Dealing with command line variables

getopts('hu:p:n:ed:');

# show help screen
if ($opt_h){
  &usage;
}
# $opt_p holds the password. If not defined, password will be asked
if (defined $opt_p){
  $password=$opt_p;
}
elsif ($password eq '') {
  &getPassword;
}

# $opt_u holds the user name what connects to the database. Defaults 'root' if not defined
if (defined $opt_u){
  $user=$opt_u;
} elsif ($user eq '') {
  $user="root";
}

# $opt_n holds the number of rows in result. Defaults 10.
if (defined $opt_n){
  $rowlimit=$opt_n;
} else {
  $rowlimit=10;
}

# $opt_d holds the path of mysql datafiles (base dir). Defaults /var/lib/mysql
if (defined $opt_d){
  $datadir=$opt_d;
} else {
  $datadir="/var/lib/mysql";
}

# if $opt_e defined, then the scripts supresses the header printig. Useful to sorting.
if ($opt_e){
  $header=0;
} else {
  $header=1;
}
# Bring in MySQL root password, echo on console disabled during security reasons
sub getPassword {
print "Please add the mysql root password: ";
  ReadMode('noecho');
  $password = ReadLine(0);
  ReadMode('normal');
  chomp($password);
  print "\n";
}

sub usage {
  print "Usage: ./checkfragmentation.pl [ -h ] [ -e ] [ -u user ] [ -p password ] [ -d mysqldatadir ] [ -n NUM ] \n";
  print " -h                 this help screen\n";
  print " -e                 no print header - useful to sort the results\n";
  print " -u username        username with connect to mysql. Defaults 'root'\n";
  print " -p password        password with connect to mysql. If not provided, you'll be asked for it.\n";
  print " -d mysqldatadir    full path of mysql data files. Defaults '/var/lib/mysql'\n";
  print " -n NUM             number of rows to display. Defaults 10\n";
  exit 0;
}
# Connect to database on localhost to information_schema as root
$dbh = DBI->connect('dbi:mysql:information_schema',$user,$password) or die "Connection error: $DBI::errstr\n";

# SQL query for table name, table row number, data size, index size, total size (data+index), ratio of index / data
$sql = "SELECT CONCAT(table_schema, '.', table_name),
       CONCAT(ROUND(table_rows / 1000000, 2))                                    rows,
       CONCAT(ROUND(data_length / ( 1024 * 1024 * 1024 ), 2))                    DATA,
       CONCAT(ROUND(index_length / ( 1024 * 1024 * 1024 ), 2))                   idx,
       CONCAT(ROUND(( data_length + index_length ) / ( 1024 * 1024 * 1024 ), 2)) total_size,
       ROUND(index_length / data_length, 2)                                      idxfrac
       FROM   information_schema.TABLES
       ORDER  BY data_length + index_length DESC
       LIMIT  $rowlimit;
";
$sth = $dbh->prepare($sql);

# Executing query
$sth -> execute or die "SQL error: $DBI::errstr\n";

# Drawing table header
if ($header==1){
  printf ("%-40s%20s%17s%18s%18s%18s%18s%20s\n","Table name","Number of rows (M)","Size of data (G)","Size of Index (G)","Total Size (G)","Data/Index ratio","Size on disk (G)","Fragmentation ratio");
  print("=========================================================================================================================================================================\n");
}
# Fetching data row-by-row
while (@row = $sth->fetchrow_array) {
        $datafileraw=$row[0];
        # Creating file name from schema_name.table_name
        $datafileraw =~ s/\./\//;
        # Checking filesize of table. The result displayed in gigabytes
        $filesize = -s "$datadir/$datafileraw.ibd";
        $filesize = ($filesize/1024/1024/1024);
        eval {
        $fragmentation = ($filesize / $row[4]);
    };
        # Print table of all the data
        printf ("%-40s%20s%17s%18s%18s%18s%18.2f%20.2f\n",$row[0],$row[1],$row[2],$row[3],$row[4],$row[5],$filesize,$fragmentation);
}
