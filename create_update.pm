#!/usr/bin/perl

use warnings;
use strict;
use File::Basename;
use File::Spec::Functions 'catfile';
use File::Find;
use Date::Format;
use Cwd 'abs_path';
    
my $update_root = abs_path(catfile(dirname($0),"update"));
my $fhem_root = catfile($update_root,"FHEM");
my $output_file = catfile($update_root,"control_venetian.txt");

print("update root directory: $update_root\n");

my @dirs = ();
my @files= ();

sub wanted(){
	if (-d $File::Find::name){
        push @dirs, $File::Find::name;
	} else {
        push @files, $File::Find::name;
	}
}

sub short{
	my ($result) = @_;
	$result =~ s/$update_root\/(.*)/$1/g;
	return $result;
}

find(\&wanted,$fhem_root);

open(my $fh, ">", $output_file) or die "Could not open file '$output_file' $!";

foreach my $dir (sort(@dirs)) {
	my $short = short($dir);
	print $fh "DIR $short\n";
}

foreach my $file (sort(@files)){
    my $short = short($file);
	my @stat = stat($file);
	my $date = time2str("%Y-%m-%d_%H:%M:%S", $stat[9]);
	my $size = $stat[7];
	print $fh "UPD $date $size $short\n";
	
}

close($fh);