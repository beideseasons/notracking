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


sub Gardener_Initialize {
    my ($hash) = @_;
    $hash->{DefFn}      = 'Gardener_Define';
    #$hash->{UndefFn}    = 'Gardener_Undef';
    #$hash->{SetFn}      = 'Gardener_Set';
    #$hash->{GetFn}      = 'Gardener_Get';
    #$hash->{AttrFn}     = 'Gardener_Attr';
    #$hash->{ReadFn}     = 'Gardener_Read';    
    $hash->{NotifyFn}     = 'Gardener_Notify';
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
	
}

sub Gardener_Get {
	my ($hash,$a,$h) = @_;
    my $cmd = $a->[1];
    if ($cmd eq "?"){
        return "check:noArg";
    } elsif ($cmd eq "check") {
    	Gardener::check($hash)
    }
}

package Gardener;


sub Gardener::check {
    my ($hash) = @_;
	my @devices = split / /, $hash->{devices};
	
	foreach my $device (@devices) {
		check_device($hash,$device)
	}
	return;
}

sub Gardener::check_device{
    my ($hash,$device) = @_;
	my $dblog = $hash->{DBlog};
	if (~defined($dblog)) {
		return "Error: Device $device is missing the DBlog attribute!";
	}
	my @moisture_hist = get_history($dblog, $device, "moisture");
	return;
}

sub get_history {
	my ($hash, $device, $reading) = @_;
	my $dblog = $hash->{DBlog};
    my $end_time = 0;
	my $start_time = $end_time - 1;
	
	my $query_result = main::fhem("get $dblog - - $start_time $end_time $device:$reading");
	foreach my $line (split /\n/, $query_result) {
		my ($timestamp, $value) = split / /, $line;
	}
	
	
	
}




1; # End of the file