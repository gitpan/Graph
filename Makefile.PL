use ExtUtils::MakeMaker;

require 5.005;

use Getopt::Long;

my $renum;

die "$0: Usage: $0 [--renum]\n"
    unless (GetOptions('renumber' => \$renum) && @ARGV == 0);

do 'util/renum.pl' if $renum;

WriteMakefile(
	      NAME            => 'Graph',
	      VERSION_FROM    => 'lib/Graph.pm',
	      PREREQ_PM	      =>
	      	{
		    'Heap'		=> 0,
		    'List::Util'	=> 0,
		    'Math::Complex'	=> 0,
		    'Test::More'	=> 0,
		},
	      );
