#!/usr/bin/perl
use JSON::XS;
use Data::Printer alias => dp;
use Parallel::ForkManager;
use Time::HiRes qw/gettimeofday/;
use POSIX       qw(strftime);
use DB_File;
use IO::Socket;

my($sock, $msg, $port, $ipaddr, $hishost, 
   $MAXLEN, $PORTNO, $TIMEOUT);

$MAXLEN  = 1024;
$PORTNO  = 8089;
$TIMEOUT = 10;

$data{"count"} = 0;

my $MAX_PROCESSES = 2;
my $dumpfile = 'db1.txt';

open DATA, $dumpfile or die "cant open $dumpfile: $!";

my $count = 0;

my $pm = new Parallel::ForkManager($MAX_PROCESSES);

while ( my $line = <DATA> ) {
   $data{"count"}++;
   my $pid = $pm->start and next;

   my $json_hash  = decode_json $line;
   my $name = $json_hash->{name};
   my $input_data;
   my $result;
   foreach my $point_array ( @{$json_hash->{points}} ){
      #dp $point_array;
      my $extra_tag = "";
      my $time = $point_array->[0];
      my $value = $point_array->[2];
      my $hostname = $point_array->[3];
      if ($value =~ /[a-z|A-Z]/){
         my $tmp = $value;
         $value = $hostname;
         $hostname = $tmp;

      }
      $count++;

       if ($name =~/(.*)\.(.*)\.$hostname\.(.*)/){
           $sitename =  $2;
           $name = $3;
       }           
           
       if ($name =~/df\.(.*)\.(.*)/){
          $extra_tag = ",mount=$1 ";
          $name = "df.${2}";
       }

       if ($name =~/network\.(.*)\.(.*)/){
           $extra_tag = ",nic=$1";
           $name = "network.$2";
       }       
                              
        $input_data = $input_data . "${name}.1m,hostname=$hostname,site=$sitename$extra_tag value=$value ${time}000000\n";       
        
        dp $input_data;
        
        $sock = IO::Socket::INET->new(Proto     => 'udp',
                                  PeerPort  => $PORTNO,
                                  PeerAddr  => 'localhost')
        or die "Creating socket: $!\n";
      
        $sock->send($input_data) or die "send: $!";
    
        print "Server $hishost responded $input_data \n";
   }
   $pm->finish;

}
$pm->wait_all_children;
