##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

# $Id$

use v5.10.1;
use strict;
use warnings;
use POSIX;
use experimental "smartmatch";
use DateTime::Format::Strptime;


sub Gardener_Initialize {
    my ($hash) = @_;
    $hash->{DefFn}      = 'Gardener_Define';
    #$hash->{UndefFn}    = 'Gardener_Undef';
    #hash->{SetFn}      = 'Gardener_Set';
    $hash->{GetFn}      = 'Gardener_Get';
    #$hash->{AttrFn}     = 'Gardener_Attr';
    #$hash->{ReadFn}     = 'Gardener_Read';    
    #$hash->{NotifyFn}     = 'Gardener_Notify';
    $hash->{parseParams} = 1;
	$hash->{AttrList} =
	  "devices " . 
	  "update_interval " .
	  "review_interval " .
	  "min_moisture ".
	  "DBlog ";      
    return;
}


sub Gardener_Define {
    my ($hash, $a, $h) = @_;    
    return;
}

sub Gardener_Notify {
    my ($own_hash, $dev_hash) = @_;
    my $ownName = $own_hash->{NAME}; # own name / hash  
    return "" if(IsDisabled($ownName)); # Return without any further action if the module is disabled
    
    my $devName = $dev_hash->{NAME}; # Device that created the events
	return;
}

sub Gardener_Get {
	my ($hash,$a,$h) = @_;
    my $cmd = $a->[1];
    if ($cmd eq "check") {
    	my ($verdict, $messages) = Gardener::check($hash);
    	return $messages;
    } else {
    	return "unknown argument $cmd choose one of check:noArg";
    }
}

package Gardener;


sub Gardener::check {
    my ($hash) = @_;
	my @devices = split / /, $hash->{devices};
	my $verdict = 0;
	my $messages = "";
	
	
	foreach my $device (@devices) {
		my ($d_verdict, $d_message) = check_device($hash,$device);
		$verdict += $d_verdict;
		$messages .= $d_message;
	}
	
    main::readingsBeginUpdate($hash);
    main::readingsBulkUpdate($hash, "status", $verdict==0 ? "good":"problem" );
    main::readingsBulkUpdate($hash, "status_message", $messages );
    main::readingsEndUpdate($hash, 1);
	
	return;
}

sub Gardener::check_device{
    my ($hash,$device) = @_;
    my $myname = $hash->{NAME};
	my $dblog = main::AttrVal($myname,"DBlog",undef);
	my $verdict = 0;
	my $message = "report for plant $device:\n";
	
	if ( ~defined $dblog ) {
		return 1, "Error: Device $device is missing the DBlog attribute!";
	}
	my @moisture_hist = get_history($dblog, $device, "moisture");
	
	if (scalar(@moisture_hist) == 0) {
		return 1, "Error reading history for plant $device!\n";
	} else {
	    my $max_moisture = max(@moisture_hist);
	    if ($max_moisture < AttrVal($device,"min_moisture",20)) {
	        $verdict +=1;
	        $message .= "  moisture is too low: $max_moisture% instead of $hash->{min_moisture}%\n";
	    } else {
	        $message .= "  moisture is good: $max_moisture%\n";
	    }
	}
	$message .="\n";
	
	return ($verdict, $message);
	 
}

sub get_history {
	my ($hash, $device, $reading) = @_;
    my $myname = $hash->{NAME};
	my $dblog = main::AttrVal($myname,"DBlog",undef);
	my $now = datetime_from_timestamp( main::TimeNow() );
    my $review_interval = main::AttrVal($myname,"review_interval","1440");
    
    my $end_time = timestamp_from_datetime( $now );
    
    my $start_time = timestamp_from_datetime( $now->subtract( minutes=>$review_interval ) );
    
	my $query_result = main::fhem("get $dblog - - $start_time $end_time $device:$reading");
	my @result = ();
	
	foreach my $line (split /\n/, $query_result) {
		my ($timestamp, $value) = split / /, $line;
		  push( @result, ($timestamp, $value) );
	}
	
	
	return @result;
}

# strangely fhem always uses string to represent timestamps
# so we always need to convert the stirngs to DateTime objects to do some math on them
# convert a DateTime to a fhem timestamp string

sub timestamp_from_datetime {
    my ($dt) = @_;
    my $strp = DateTime::Format::Strptime->new(
       pattern => '%F_%T',
       time_zone => 'local',
    );
    return $strp->format_datetime($dt);
}

# convert a timestamp string to a DateTime object
sub datetime_from_timestamp {
    my ($timestamp) = @_;
    my $strp = DateTime::Format::Strptime->new(
	   pattern => '%F_%T',
	   time_zone => 'local',
	);
	return $strp->parse_datetime($timestamp);
}




1; # End of the file