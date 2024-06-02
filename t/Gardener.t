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
#use Time::HiRes "gettimeofday";
#use Test::MockModule;

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
    test_check_reading_history_low();
    test_send_email();
    
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
    
	prepare_database($device,$dblog,$hash->{NAME} );
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
    prepare_database($device, "logdb",$hash->{NAME}, "#randomstuff\n");

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
    my $reading = "moisture";
    
    prepare_database($device, "logdb",$hash->{NAME});
    
    my $history = Gardener::get_history($hash,$device,$reading);
    ok( scalar @{$history->{list}} > 0);
    ok(defined $history->{min});
    ok(defined $history->{max});
    ok(defined $history->{average});
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

sub test_check_reading_history_low {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
    	NAME=>"my_name_is",
    };
    my $device = "some_device";
    my $reading = "moisture";
    prepare_database($device, "logdb",$hash->{NAME});
    set_attr($device,"min_moisture",80);
    my $result = Gardener::check_reading_history($hash,$device,$reading);	
	ok(!$result->{verdict});
	like($result->{message},qr/too low/);
	
}

sub test_send_email {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
    	NAME=>"call_be_crazy",
    };
    my $verdict = 1;
    my @messages = ("line 1","","  line 2");
    set_attr($hash->{NAME},"MSGMail","email");
    set_attr($hash->{NAME},"send_email","always");
    set_fhem_mock("set email clear","");
    set_fhem_mock("set email add .line 1","");
    set_fhem_mock("set email add .","");
    set_fhem_mock("set email add .  line 2","");
    set_fhem_mock("set email send","");
    Gardener::trigger_email($hash,$verdict,@messages);	
    my @fhem_history = @{get_fhem_history()};
    is($fhem_history[0],"set email clear");
    is($fhem_history[1],"set email add .line 1");
    is($fhem_history[2],"set email add .");
    is($fhem_history[3],"set email add .  line 2");
    is($fhem_history[4],"set email send");
    is($fhem_history[5],"set email clear");
}

######################################################
# functions to prepare data for tests

# test data to fill into a mock DbLog
# queries to get the test data:
# get logdb - - 2017-01-25_08:00:00 2017-01-26_08:00:00 Palmfarn:battery
# get logdb - - 2017-01-25_08:00:00 2017-01-26_08:00:00 Palmfarn:moisture
# get logdb - - 2017-01-25_08:00:00 2017-01-26_08:00:00 Palmfarn:conductivity

sub get_dblog_test_data {
	my ($reading) = @_;
    my $dblog_test_data = {
moisture => q{2017-01-25_00:00:06 20.1
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
2017-01-25_23:00:09 20.1
#Palmfarn:moisture:::},   

battery => q{017-01-25_08:00:06 99
2017-01-25_09:00:08 99
2017-01-25_10:00:10 99
2017-01-25_11:00:08 99
2017-01-25_12:00:05 99
2017-01-25_13:00:07 98
2017-01-25_14:00:05 99
2017-01-25_15:00:08 99
2017-01-25_16:00:07 99
2017-01-25_17:00:10 99
2017-01-25_18:00:08 99
2017-01-25_19:00:06 99
2017-01-25_20:00:06 99
2017-01-25_21:00:08 99
2017-01-25_22:00:06 99
2017-01-25_23:00:09 99
2017-01-26_00:00:06 99
2017-01-26_01:00:09 99
2017-01-26_02:00:10 99
2017-01-26_03:00:07 99
2017-01-26_04:00:08 99
2017-01-26_05:00:08 99
2017-01-26_06:00:08 99
2017-01-26_07:00:09 99
#Palmfarn:battery:::},

conductivity => q{2017-01-27_21:37:29 430
2017-01-25_22:03:02 507
2017-01-25_22:20:48 490
2017-01-25_23:01:10 421
2017-01-26_00:01:10 417
2017-01-26_01:01:12 405
2017-01-26_02:01:11 398
2017-01-26_03:01:09 393
2017-01-26_04:01:11 391
2017-01-26_05:01:11 388
2017-01-26_06:01:16 386
2017-01-26_07:01:11 384
#Palmfarn:conductivity:::},
    };
    return $dblog_test_data->{$reading};
}

sub prepare_database {
    my ($device, $dblog, $name, $user_test_data)= @_;

    set_attr($name,"review_interval","1440");
    set_attr($name,"DbLog",$dblog);
    
    my $now = "2017-01-26_08:00:00";
    fhem_set_time($now);
    my $start_time = "2017-01-25_08:00:00";
    my $end_time = $now;
    foreach my $reading (("moisture","battery","conductivity")) {
    	my $data = undef;
    	if (defined $user_test_data) {
    		$data = $user_test_data;
    	} else {
    		$data = get_dblog_test_data($reading);
            ok(defined $data, "test data for $reading must be defined");
    	}
        set_fhem_mock("get $dblog - - $start_time $end_time $device:$reading", $data );
    }     
}

1; #end of file