# -*- Mode: Perl -*-
 
use ExtUtils::MakeMaker;
use Config;
 
&WriteMakefile(
               'NAME'     => 'Graph',
               'LINKTYPE' => '$(INST_PM)',
	       'VERSION'  => '0.01',
               'dist'     => { SUFFIX => 'gz', COMPRESS => 'gzip -f' },
               'clean'    => {'FILES' => '*~'},
);
