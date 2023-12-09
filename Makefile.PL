use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Gardener',
    AUTHOR           => q{Christian Kühnel <christian.kuehnel@gmail.com>},
    VERSION		     => '0.1.0',
    #ABSTRACT_FROM    => 'lib/Venetian.pm',
    LICENSE          => 'Apache_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::MockModule' => 0,
        'Time::HiRes' => 0,
        'Test::Perl::Critic' => 0,
        'Test::Pod' => 0,
        'Devel::Cover::Report::Coveralls' => 0,
    },
    PREREQ_PM => {
        'experimental' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'fhem-venetian-*' },
);

#
 sub MY::postamble {
    return q{

fhem_local_deploy:
	$(CP) -p lib/Gardener.pm ~/git/fhem/FHEM/97_Gardener.pm

fhem_local_fetch:
	$(CP) -p ~/git/fhem/FHEM/97_Gardener.pm lib/Gardener.pm 

fhem_release: 
	$(CP) -p lib/Gardener.pm update/FHEM/97_Gardener.pm
	cd update;git log -n10 > CHANGED
	perl create_update.pm
}
};

1;

