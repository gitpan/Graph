use Graph::Undirected;
use Graph::Directed;
use strict;

print "1..2\n";

my $g = new Graph::Undirected;
my $d;

$g->add_weighted_edge("r1", 1, "l1");

$d = $g->SSSP_Dijkstra("r1");
print "ok 1\n" if $g eq "r1=l1";
print "ok 2\n" if $d eq "r1=l1";

