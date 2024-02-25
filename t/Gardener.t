##############################################
#
# This is open source software licensed unter the Apache License 2.0
# http://www.apache.org/licenses/LICENSE-2.0
#
##############################################

use strict;
use warnings;
use v5.10.1;
use experimental "smartmatch";
use Test::More;
use Time::HiRes "gettimeofday";
use Test::MockModule;

use Gardener;

use lib "t"; 
use fhem_test_mocks;

##############################################################################################
sub test_Gardener {
	test_check();
    test_check_no_devices();
    test_check_device_nodblog();
    test_datetime_from_timestamp();
    test_get_history();
    test_check_device_empty_history();
    
    done_testing();
}

test_Gardener();

##############################################################################################

sub test_check {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
        "NAME" => "gardener"
    }; 
    my $device = "some_device";
    my $dblog = "dblog";
    set_attr($hash->{NAME}, "DbLog", $dblog);
    set_attr($hash->{NAME}, "devices", $device);
    #set_attr("gardener", "DbLog", $dblog);
    
	prepare_database($device,"moisture",$dblog,$hash->{NAME}, get_test_data() );
    Gardener::check($hash);
    print(ReadingsVal("gardener","status_message",undef)."\n");
    is(ReadingsVal("gardener","status",undef),"good");
}

sub test_check_no_devices {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
        "NAME" => "gardener"
    }; 
    Gardener::check($hash);
    is(ReadingsVal("gardener","status",undef),"problem");
    like(ReadingsVal("gardener","status_message",undef),qr/devices/);       
}

sub test_check_device_nodblog {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
    	"NAME" => "gardener"
    }; 
    my ($verdict, $messages) = Gardener::check_device($hash,"device1");
    ok(~$verdict);
    like($messages, qr/DbLog/);
}

sub test_check_device_empty_history {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $testdata = "";
    my $dblog = "dblog";
    my $hash = {
        "NAME" => "gardener"
    };	
    my $device ="some";
    my $reading = "moisture";
    prepare_database($device, $reading,"logdb",$hash->{NAME}, "#randomstuff\n");

    my ($verdict, @messages) = Gardener::check_device($hash,$device);
    ok(~$verdict);
    like(join(';',@messages), qr/Error/);
}


sub test_get_history {
	# command to get test data: 
	# get logdb - - 2017-01-25 2017-01-26 Palmfarn:temp

    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
        "NAME" => "gardener"
    };
    my $device = "dev1";
    my $reading = "read1";
    
    prepare_database($device, $reading,"logdb",$hash->{NAME}, get_test_data());
    
    my @history = Gardener::get_history($hash,$device,$reading);
    
    	
}

sub test_datetime_from_timestamp {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $timestamp = '2017-01-25_21:00:08';
	my $dt = Gardener::datetime_from_timestamp($timestamp);
	is($dt->year, 2017);
    is($dt->month, 1);
    is($dt->day, 25);
    is($dt->hour, 21);
    is($dt->minute, 0);
    is($dt->second, 8);
    is(Gardener::timestamp_from_datetime($dt),$timestamp);

    # now with a whitespace as separator
    my $timestamp2 = '2017-01-25 21:00:08';
    is($dt, Gardener::datetime_from_timestamp($timestamp2)); 
}

######################################################
# functions to prepare data for tests


sub get_test_data {
    return 
q{#somedevice:somereading:::
2017-01-25_00:00:06 20.1
2017-01-25_01:00:08 20.1
2017-01-25_02:00:06 20.1
2017-01-25_03:00:06 20.0
2017-01-25_04:00:08 20.0
2017-01-25_05:00:09 20.0
2017-01-25_06:00:10 20.0
2017-01-25_07:00:11 20.0
2017-01-25_08:00:06 20.0
2017-01-25_09:00:08 20.0
2017-01-25_10:00:10 20.1
2017-01-25_11:00:08 20.2
2017-01-25_12:00:05 20.4
2017-01-25_13:00:07 20.4
2017-01-25_14:00:05 20.4
2017-01-25_15:00:08 20.4
2017-01-25_16:00:07 20.3
2017-01-25_17:00:10 20.2
2017-01-25_18:00:08 20.1
2017-01-25_19:00:06 20.1
2017-01-25_20:00:06 20.1
2017-01-25_21:00:08 20.1
2017-01-25_22:00:06 20.1
2017-01-25_23:00:09 20.1}   
}

sub prepare_database {
    my ($device, $reading, $dblog, $name, $testdata)= @_;


    set_attr($name,"review_interval","1440");
    set_attr($name,"DbLog",$dblog);
    
    my $now = "2017-01-26_08:00:00";
    fhem_set_time($now);
    my $start_time = "2017-01-25_08:00:00";
    my $end_time = $now;
    set_fhem_mock("get $dblog - - $start_time $end_time $device:$reading", $testdata);     
}

1; #end of file