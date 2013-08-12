#!/usr/bin/perl
#
# CheckConnections.pl
# Checks connections against MySQL server
#

use DBI;                # Connect MySQL database, run queries
use Socket;             # DNS resolve of hosts
use Config::Simple;     # read .my.cnf file
use Getopt::Std;        # parse command line arguments
use Switch;             # Use 'case'
use Term::ReadKey;      # Read password in safe

# Load credentials from ~/.my.cnf if exists ([client] section)
# If password remains empty (eg. no ~/.my.cnf file) it will set from -p or asked later
$configfile = $ENV{"HOME"}."/.my.cnf";
if ( -e $configfile){
    $config = new Config::Simple(filename=>$configfile);
    $user = $config->param("client.user"), "\n";
    $password = $config->param("client.password"), "\n";
}

# Dealing with command line variables
getopts('hu:p:scrdl');

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
if (defined $opt_l){
  $wherelive=" WHERE Command NOT LIKE 'Sleep' "
}
# If -s provided it will show connections by host
if ($opt_s){
$header="Connections                            Hostname\n===============================================\n";
$sql="SELECT
                COUNT(*) AS conn_count,
                SUBSTRING_INDEX(host,':',1) AS ip
        FROM
                INFORMATION_SCHEMA.PROCESSLIST" . $wherelive . "
        GROUP BY
                ip
        ORDER BY
                conn_count
        DESC";
$type="host";
&queryconn($type);

}
# If -c provided it will show connections by users
if ($opt_c) {
$header="Connections                            Username\n===============================================\n";
$sql="SELECT
        COUNT(*) AS conn_count,
        user
    FROM
        INFORMATION_SCHEMA.PROCESSLIST" .$wherelive . "
    GROUP BY
        user
    ORDER BY
        conn_count
    DESC";
$type="user";
&queryconn($type);
}
# If -d provided it will show connections by database
if ($opt_d) {
    $header="Connections                       Database\n===============================================\n";
    $sql="SELECT
            COUNT(*) AS conn_count,
            db
        FROM
                    INFORMATION_SCHEMA.PROCESSLIST" .$wherelive. "
            GROUP BY
                    db
            ORDER BY
                    conn_count
            DESC";
    $type="db";
    &queryconn($type);
}

# If no -s -c -d were provided, show connections for all available options
if ($type eq ''){
    $header="Connections                            Hostname            Username            Database\n=======================================================================================\n";
    $sql ="SELECT
        COUNT(*) AS conn_count,
        SUBSTRING_INDEX(host,':',1) AS ip,
        user,
        db
    FROM
        INFORMATION_SCHEMA.PROCESSLIST" .$wherelive ."
    GROUP BY
        ip,
        user,
        db
    ORDER BY
        conn_count, ip
    DESC
        ";
    $type="full";
    &queryconn($type);
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
  print "Usage: ./checkconnections.pl [ -h ] [ -u user ] [ -p password ] [ -s ] [ -c ] [ -r ] [ -d ]\n";
  print "  if none of -s -c -d are given, script provides a full connection list\n";
  print " -h                 this help screen\n";
  print " -u username        username with connect to mysql. Defaults 'root'\n";
  print " -p password        password with connect to mysql. If not provided,asks for it.\n";
  print " -s                 show connections by server\n";
  print " -c                 show connections by users\n";
  print " -d                 show connections by database\n";
  print " -l                 print only connections which are not in 'Sleep' state";
  print "\n";
  exit 0;
}

# This function queries the db for connection parameters.
sub queryconn($type) {
    $dbh = DBI->connect('dbi:mysql:information_schema',$user,$password) or die "Connection error: $DBI::errstr\n";
    $sth = $dbh->prepare($sql);
    $sth -> execute or die "SQL error: $DBI::errstr\n";
    print $header;
        while (@row = $sth->fetchrow_array) {
        # When query result can contain ip adresses, queries DNS for hostnames
        if ($type eq "host" or "full"){
                if($row[1] =~ /^\d+.\d+.\d+.\d+$/) {
                    $hostname = gethostbyaddr(inet_aton($row[1]),AF_INET);
                } else {
                        $hostname = $row[1];
                }
        }
        # Formatted output for results
        switch($type){
            case "full" {
                printf("%12d%35s%20s%20s\n",$row[0],$hostname,$row[2],$row[3]);
                break;
            }
            case "host" {
                printf("%12d%35s\n",$row[0],$hostname);
                break;
            }
            case "user" {
                printf("%12d%35s\n",$row[0],$row[1]);
                break;
            }
            case "db" {
                printf("%12d%35s\n",$row[0],$row[1]);
                break;
            }

        }
    }
    print "\n";
}
