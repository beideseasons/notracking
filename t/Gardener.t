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
    test_check_device_nodblog();
    test_get_history();
    
    done_testing();
}

test_Gardener();

##############################################################################################

sub test_check {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
    	"devices" => "device1 device2",
    }; 
    Gardener::check($hash);
    # TODO: add some checks here?!
}

sub test_check_device_nodblog {
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
    	"DBlog" => "dblog",
    }; 
    my $result = Gardener::check_device($hash,"device1");
    like($result,qr/Error/)
}

sub test_get_history {
	# command to get test data: 
	# get logdb - - 2017-01-25 2017-01-26 Palmfarn:temp
    my $testdata = 
q{2017-01-25_00:00:06 20.1
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
2017-01-25_23:00:09 20.1};
    note( "test case: ".(caller(0))[3] );   
    main::reset_mocks();
    my $hash = {
    	"DBlog" => "dblog",
    };
    my $device = "dev1";
    my $reading = "read1";
    set_fhem_mock("get $hash->{DBlog} - - 0 0 $device:$reading",$testdata);
    my @history = Gardener::get_history($hash,$device,$reading);
    
    	
}


1; #end of file