use ExtUtils::MakeMaker;

require 5.005;

use Getopt::Long;

my $renum;

GetOptions('renumber' => \$renum);

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
