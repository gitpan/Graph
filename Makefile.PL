require 5.004_04;

use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM => 'lib/Graph.pm',
    NAME         => 'Graph',
    PREREQ_PM    => {Heap => 0.01},
    dist         => { COMPRESS => 'gzip' },
);
