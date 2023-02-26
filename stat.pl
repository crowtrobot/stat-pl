#!/usr/bin/perl 

$interval = 1;

while ($#ARGV >= 0) {
    $argument=shift;
    if ( $argument eq "-i" ) {
	$interval = shift;
    }
    if ( $argument eq "-h" ) {
	print "stat.pl monitors some basic I/O stats (top style). \n";
	print "Usage:  stat.pl [-i num]\n";
	print "   -i    Interval.  Specify the number of seconds delay between updates.\n";
	exit 1;
    }
}

if ($interval < 1) {
    die "Can't have interval less than 1"
}

###Setup for timestamps
@months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);

sub commify {
    local($_) = shift;
    1 while s/^(-?\d+)(\d{3})/$1,$2/;
    return $_;
} 


$first=2;
while (1)
  {
      if ($count++ < 4) {
	  printf("\033[2J");
      }
      open(IN, "< /proc/net/dev");
      printf("\033[H");
      #Print a time stamp
      ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
      $year = 1900 + $yearOffset;
      $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
      printf("%02d:%02d:%02d %s %s %02d, %04d\n", $hour,$minute,$second, $weekDays[$dayOfWeek], $months[$month], $dayOfMonth, $year);
      if ($first==1)
      {
	  printf("Ethernet Stats     ---Gathering first pass data for $interval seconds---  \n");
      }
      else
      {
	  printf("Ethernet Stats ------------RECV-----------      -----------XMIT-----------\n");
      }
      
      
      printf("%8s:%12s%12s%8s%12s%12s%8s      \033[m\n", "INTF", "pkt/s", "B/s", "B/pkt","pkt/s", "B/s", "B/pkt");
      <IN>;
      <IN>;
    AGAIN:  while (<IN>)
    {
	($name, $rxb, $rxp, $rxe, $rxd, $rxfi, $rxfr, $rxc, $rxm, $txb, $txp, $txe, $txd, $txfi, $txcol) =
	    m/([a-z0-9]*):\s*([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+/;
	
	next AGAIN if /lo/;
	
	if ($name =~ /^bond|^br/)
	{
	    $fmt ="\033[1m";	
	}
	else
	{
	    $fmt = "";
	}

	printf("%s%8.8s:%12u%12s%8.1f%12u%12s%8.1f      \033[m\n",
	       $fmt,
	       $name,
	       int(($rxp-$lastrxp{$name})/$interval),
	       &commify(int(($rxb-$lastrxb{$name})/$interval)),
	       ($rxb-$lastrxb{$name})/(1+($rxp-$lastrxp{$name})),
	       int(($txp-$lasttxp{$name})/$interval),
	       &commify(int(($txb-$lasttxb{$name})/$interval)),
	       ($txb-$lasttxb{$name})/(1+($txp-$lasttxp{$name})));
	
	$lastrxp{$name} = $rxp;
	$lastrxb{$name} = $rxb;
	$lastrxe{$name} = $rxe;
	$lasttxp{$name} = $txp;
	$lasttxb{$name} = $txb;
	$lasttxe{$name} = $txe;
	
      }
    close(IN);



#       Field  1 -- # of reads completed
#	    This is the total number of reads completed successfully.
#	Field  2 -- # of reads merged, field 6 -- # of writes merged
#	    Reads and writes which are adjacent to each other may be merged for
#	    efficiency.  Thus two 4K reads may become one 8K read before it is
#	    ultimately handed to the disk, and so it will be counted (and queued)
#	    as only one I/O.  This field lets you know how often this was done.
#	Field  3 -- # of sectors read
#	    This is the total number of sectors read successfully.
#	Field  4 -- # of milliseconds spent reading
#	    This is the total number of milliseconds spent by all reads (as
#	    measured from __make_request() to end_that_request_last()).
#	Field  5 -- # of writes completed
#	    This is the total number of writes completed successfully.
#	Field  7 -- # of sectors written
#	    This is the total number of sectors written successfully.
#	Field  8 -- # of milliseconds spent writing
#	    This is the total number of milliseconds spent by all writes (as
#	    measured from __make_request() to end_that_request_last()).
#	Field  9 -- # of I/Os currently in progress
#	    The only field that should go to zero. Incremented as requests are
#	    given to appropriate struct request_queue and decremented as they finish.
#	Field 10 -- # of milliseconds spent doing I/Os
#	    This field is increases so long as field 9 is nonzero.
#	Field 11 -- weighted # of milliseconds spent doing I/Os
#	    This field is incremented at each I/O start, I/O completion, I/O
#	    merge, or read of these stats by the number of I/Os in progress
#	    (field 9) times the number of milliseconds spent doing I/O since the
#	    last update of this field.  This can provide an easy measure of both
#	    I/O completion time and the backlog that may be accumulating.


	printf("\n        -----------READ/s----------   ----------WRITE/s---------\n");
	printf("%9s %5s/%-5s %6s %8s %5s/%-5s%6s %8s%8s %5s   \033[m\n",
	       "DISK",
	       "IO","MRG","TPUT", "AVGIOms", "IO", "MRG", "TPUT", "AVGIOms", "QLEN/s", "%QFUL");
    open(DIN, "< /proc/diskstats") || open(DIN, "< /proc/partitions");
 DAGADIN:  while (<DIN>)
      {
	#($maj, $min, $size, $name, $n1, $n2, $n3, $n4, $n5, $n6, $n7, $n8, $n9, $n10, $n11) =
	#  m/^\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+(\S+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+)\s+/;
	($maj, $min, $name, $n1, $n2, $n3, $n4, $n5, $n6, $n7, $n8, $n9, $n10, $n11) =
	  m/^\s+([0-9]+)\s+([0-5]+)\s+(\S+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+)\s+([0-9-]+)\s+/;
#	printf ("name=<%s> maj=<%d> min=<%d>\n", $name, $maj, $min);
	next DAGADIN if ($name !~ /^[a-z]d[a-z]+$|sr[0-9]+|md[0-9]+|^dm.*$|nvme[0-9]+n[0-9]+/);


	$reads = ($n1-$lastn1{$name});
	if ($reads == 0) {
	  $reads = 1;
	}
	$writes = ($n5-$lastn5{$name});
	if ($writes == 0) {
	  $writes = 1;
	}
	
	$name =~ s/scsi/sd/g;
	$name =~ s/ide/hd/g;
	$name =~ s/host//g;
	$name =~ s/bus//g;
	$name =~ s/target//g;
	$name =~ s/\/lun[0-9]+//g;
	$name =~ s/\/disc//g;

        if ($name =~ /^md|^dm/)
	{
	    $fmt ="\033[1m";	
	}
	else
	{
	    $fmt = "";
	}

	printf("%s%9.9s:%5u/%-5u %5.1fM %8.3f %5u/%-5.4u%5.1fM %8.3f%8d %5u   \033[m\n",
	       $fmt,
	       $name,
	       int(($n1-$lastn1{$name})/$interval),
	       int(($n2-$lastn2{$name})/$interval),
	       int(((($n3-$lastn3{$name})*512.0)/(1024.0*1024.0))/$interval),
	       (($n4-$lastn4{$name})/$reads)/1000.0,
	       int(($n5-$lastn5{$name})/$interval),
	       int(($n6-$lastn6{$name})/$interval),
	       int(((($n7-$lastn7{$name})*512.0)/(1024.0*1024.0))/$interval),
	       (($n8-$lastn8{$name})/$writes)/1000.0,
	       int(($n9)/$interval),
	       int((($n10-$lastn10{$name})/10))/$interval);

	
	$lastn1{$name} = $n1;
	$lastn2{$name} = $n2;
	$lastn3{$name} = $n3;
	$lastn4{$name} = $n4;	
	$lastn5{$name} = $n5;
	$lastn6{$name} = $n6;
	$lastn7{$name} = $n7;
	$lastn8{$name} = $n8;	
	$lastn9{$name} = $n9;
	$lastn10{$name} = $n10;
	$lastn11{$name} = $n11;
	
      }
    close(DIN);
	if ($first==2) {
	    $first=1;
	} else {
	    sleep($interval);
	    if ($first==1) {
		$first=0;		
	    }
	}
  } #end while

