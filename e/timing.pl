
use strict;

use lib qw(./lib ../lib);

use Graph::Directed;
use Benchmark;

my $count = 100;
my $size = 5000;

my $base = timeit($count, sub {
    my $graph = Graph::Directed->new();
    for (1..$size) {
	$graph->add((rand() % 4711) => (rand() % 4711));
    }
});

print "Adding $size edges $count times took ", timestr($base), "\n";

my $scc = timeit($count, sub {
    my $graph = Graph::Directed->new();
    for (1..$size) {
	$graph->add((rand() % 4711) => (rand() % 4711));
    }
    my $scc = $graph->scc;
});

print "Computing SCCs $count times took ", timestr(timediff($scc,$base)), "\n";
