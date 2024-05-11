##############################################
# 
# This is open source software licensed unter the Apache License 2.0 
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use strict;
use warnings;
use experimental "smartmatch";
use Devel::StackTrace;
package main;


# general ################################
my %readings = ();
my %fhem_list = ();
my @fhem_expected_list = ();
my @fhem_history = ();
my @timer_list = ();
my %attributes = ();
my $now = undef;

sub reset_mocks{
	%readings = ();
	%fhem_list = ();
	@timer_list = ();
	@fhem_expected_list = ();
	@fhem_history = ();
    %attributes = ();
    $now = undef;
}


# Logging ################################

sub Log3{
print "Log: $_[0] , $_[1] , $_[2] \n"; 
}


# fhem command ##########################
sub fhem{
    my ($cmd) = @_;
    ok($cmd ~~ @fhem_expected_list, "fhem command: $cmd") or diag(Devel::StackTrace->new->as_string);
    push(@fhem_history,$cmd);
    return $fhem_list{$cmd};  
}

sub set_fhem_mock{
	my ($cmd, $return_value) = @_;
	$fhem_list{$cmd} = $return_value;
	push(@fhem_expected_list,$cmd);
}

sub get_fhem_history{
	return \@fhem_history;
}

sub reset_fhem_history {
	@fhem_history = ();
}

# Timer ###############################

sub InternalTimer{
	my ($time,$func,$param,$init) = @_;
	push(@timer_list, {
		"timer" => $time,
		"func" => $func,
		"param" => $param,
		"init" => $init,	
	});
	ok(scalar @timer_list > 0);
}

sub trigger_timer{
	ok(scalar @timer_list > 0);
	my @oldtimers = @timer_list;
	@timer_list = ();
	foreach my $timer (@oldtimers){
 		## no critic
 	    no strict "refs";
	    &{$timer->{func}}($timer->{param});
	    use strict "refs";	}
		## use critic
}


sub get_timer_list{
	return @timer_list;
};

# Readings ###############################################

sub ReadingsVal {
    my ($device,$reading,$default) = @_;
    ok(defined $device,"defined $device");
    ok(defined $reading,"defined $device reading $reading");
    my $value = $readings{$device}{$reading}{value};
	if (!defined $value) {
		return $default;
	}
    return $value;
}

sub ReadingsAge {
    my ($device,$reading,$default) = @_;
    my $time = $readings{$device}{$reading}{timestamp};
    #print "readings $device, $reading, $value \n";
    ok(defined $time,"ReadingsAge $device:$reading");
    return time-$time;
}

sub add_reading{
	my ($device,$reading,$value) = @_;
	add_reading_time($device,$reading,$value,time());
}

sub add_reading_time{
	my ($device,$reading,$value,$timestamp) = @_;
	$readings{$device}{$reading}{value} = $value;
	$readings{$device}{$reading}{timestamp} = $timestamp;
}

sub readingsSingleUpdate{
	my ($hash,$reading,$value,$trigger) = @_;
	my $device = $hash->{NAME};
	ok(defined $device);
	print("update reading: $device - $reading = '$value'\n");		
	add_reading($device, $reading, $value);
}		


sub readingsBeginUpdate{
	#not sure how to mock this...
}

sub readingsEndUpdate{
	#not sure how to mock this...
}

sub readingsBulkUpdate{
	my ($hash, $reading, $value) = @_;
	my $device = $hash->{NAME};
	ok(defined $device);
	add_reading($device, $reading, $value);
}

# Attributes ###############################################

sub AttrVal {
	my ($device,$name,$default) = @_;
	ok(defined $device,'device must be defined');
	ok(defined $name,'name must be defined');
	if (!defined($attributes{$device})) {
		return;
	}
    my $val = $attributes{$device}{$name};
    if (defined $val) {
    	return $val;
    }
    return $default;
}

sub set_attr {
    my ($device,$name,$value) = @_;
    $attributes{$device}{$name} = $value;
}


# Time ###############################################

sub fhem_set_time{
	($now) = @_;
}

sub TimeNow {
    return $now;	
}

1; #end module

