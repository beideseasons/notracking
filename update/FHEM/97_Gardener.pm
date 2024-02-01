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
	  "DbLog ".
	  "MSGMail ".
	  "send_email:problem_only,always,never";      
    return;
}


sub Gardener_Define {
    my ($hash, $a, $h) = @_;
    InternalTimer(gettimeofday()+10, "Gardener_periodic_update", $hash);    
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
    	Gardener::check($hash);
    } else {
    	return "unknown argument $cmd choose one of check:noArg";
    }
    return;
}

sub Gardener_periodic_update {
    my ($hash) = @_;
    my $interval = AttrVal($hash->{NAME},"update_interval",1440) * 60;
    Gardener::Log($hash,3,"periodic update");
    InternalTimer(gettimeofday()+$interval, "Gardener_periodic_update", $hash);    
    
    Gardener::check($hash);
    return;
}

######################################################
package Gardener;

sub Log {
	my ($hash, $severity, $message) = @_;
	return main::Log3($hash->{NAME},$severity, "Gardener $hash->{NAME}: $message");
}



sub Gardener::check {
    my ($hash) = @_;
	my $device_names = main::AttrVal($hash->{NAME},"devices",undef);
    my $verdict = 1;
    my @messages = ();

	if ( !defined $device_names ) {
		$verdict = 0;
		 push(@messages, "Error: no devices configured!" );
	} else {
		
		my @devices = split / /, $device_names;
		
		
		foreach my $device (@devices) {
			my ($d_verdict, @d_message) = check_device($hash,$device);
			$verdict &= $d_verdict;
			push(@messages, @d_message);
		}
	}
	
	print(join("<br>",@messages));
    main::readingsBeginUpdate($hash);
    main::readingsBulkUpdate($hash, "status", $verdict==1 ? "good":"problem" );
    main::readingsBulkUpdate($hash, "status_message", join("<br>",@messages) );
    main::readingsEndUpdate($hash, 1);
	
	trigger_email($hash,$verdict,@messages);
	
	return;
}

sub Gardener::check_device{
    my ($hash,$device) = @_;
	my $dblog = main::AttrVal($hash->{NAME},"DbLog",undef);
	my $verdict = 1;
	my @message = ("report for plant $device:");
	
	if ( !defined $dblog ) {
		my $msg = "Error: Device $hash->{NAME} is missing the DbLog attribute!";
		Log($hash, 1, $msg);
		return 0, $msg;
	}
	my @moisture_hist = get_history($hash, $device, "moisture");
	
	if (scalar(@moisture_hist) == 0) {
		my $msg = "Error reading history for plant $device!\n";
		Log($hash, 1, $msg);
		return 0, $msg;
	} 

    my $max_moisture = 0;
    foreach my $row (@moisture_hist) {
    	$max_moisture = max($max_moisture, $row->{value});
    }

    my $min_moisture =  main::AttrVal($device,"min_moisture",20);
    if ($max_moisture < $min_moisture) {
        $verdict = 0;
        push( @message, "  moisture is too low: maximum was at $max_moisture% instead of $min_moisture%");
    } else {
        push( @message,  "  moisture is good: $max_moisture%\n");
    }

	push( @message, "");
	
	return ($verdict, @message);
	 
}

sub get_history {
	my ($hash, $device, $reading) = @_;
	my $dblog = main::AttrVal($hash->{NAME},"DbLog",undef);
	my $now = datetime_from_timestamp( main::TimeNow() );
    my $review_interval = main::AttrVal($hash->{NAME},"review_interval","1440");
    
    my $end_time = timestamp_from_datetime( $now );
    
    my $start_time = timestamp_from_datetime( $now->subtract( minutes=>$review_interval ) );
    
	my $query_result = main::fhem("get $dblog - - $start_time $end_time $device:$reading","");
	Log($hash, 5, "result from query: ".$query_result);
	
	my @result = ();
	if (!defined $query_result) {
		return @result;
	}
	foreach my $line (split /\n/, $query_result) {
		if ( $line !~ m/^#/ ) {
			my ($timestamp, $value) = split / /, $line;
			  push( @result, {timestamp => $timestamp, value => $value} );
		}
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
# Sometimes date and time are separated by a " " (whitespace) and sometimes by a "_".
# So we support both options here.
sub datetime_from_timestamp {
    my ($timestamp) = @_;
    my $sep = " ";
    if ($timestamp =~ m/_/ ) {
    	$sep = "_";
    }
    my $strp = DateTime::Format::Strptime->new(
	   pattern => '%F'.$sep.'%T',
	   time_zone => 'local',
	);
	return $strp->parse_datetime($timestamp);
}

# send out email notifications
sub trigger_email {
	my ($hash,$verdict,@messages) = @_;
	my $msgmail = main::AttrVal($hash->{NAME},"MSGMail",undef);
	my $send_email = main::AttrVal($hash->{NAME},"send_email","problem_only");
	
	if (defined $msgmail){
		if ( $send_email eq "always" or (!$verdict and $send_email eq "problem_only" )) {
			main::fhem("set $msgmail clear");
			foreach my $line (@messages) {
				main::fhem("set $msgmail add $line");
			}
            main::fhem("set $msgmail send");
            main::fhem("set $msgmail clear");
		}
	}
	return;
}

# writing my own min/max functions as List::Util required compilation and that is not available on all targets
sub max { $_[$_[0] < $_[1]] }
sub min { $_[$_[0] > $_[1]] }
	


1; # End of the file