#!/usr/bin/perl -w
use strict;
use LWP::UserAgent;

#--------
my $to    = $ARGV[0];
my $title = $ARGV[1];
my $smsg  = $ARGV[2];
my $url   = 'http://chufa.lmobile.cn/submitdata/service.asmx/g_Submit';

#my $url   = 'http://dx.lmobile.cn:6003/submitdata/service.asmx/g_Submit';
my $ua    = new LWP::UserAgent;
my %param = (
    'smsg'    => "$smsg",
    'sdst'    => "$to",
#    'sprdid'  => "1012802",
    'sprdid'  => "1012818",
    'spwd'    => "k6m8jEbY",
    'scorpid' => "",
    'sname'   => "dlfhbxbw"
            );
my $response = $ua->post( $url, \%param );

open( FILE, ">>/data/log/zabbix/sendsms.log" ) || die("Could not open file");
if ( $response->is_success ) {
    #print $response->content;
    my $time1 = &get_time(0);
    print FILE "$time1 sms send success\n";
}
else {
    my $time2 = &get_time(0);
    print FILE "$time2 sms no send error\n";
}
close FILE;

#my $content = $response->content;
#print $content;

# -------------------------------------------------------------------
# Func   : get time
# Sample :
#          &get_time();
# -------------------------------------------------------------------
sub get_time {
    my $interval = $_[0] * 60;
    my ( $sec, $min, $hour, $day, $mon, $year, $weekday, $yeardate,
        $savinglightday )
      = ( localtime( time + $interval ) );
    $sec  = ( $sec < 10 )  ? "0$sec"  : $sec;
    $min  = ( $min < 10 )  ? "0$min"  : $min;
    $hour = ( $hour < 10 ) ? "0$hour" : $hour;
    $day  = ( $day < 10 )  ? "0$day"  : $day;
    $mon = ( $mon < 9 ) ? "0" . ( $mon + 1 ) : ( $mon + 1 );
    $year += 1900;
    return "$year-$mon-$day $hour:$min:$sec";
}
