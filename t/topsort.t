#                              -*- Mode: Perl -*- 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
 
######################### We start with some black magic to print on failure.
 
use lib './lib';
 
BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Graph::Directed qw(topsort);
$loaded = 1;
print "ok 1\n";
 
######################### End of black magic.
 
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

@E = (1 => 2, 1 => 3, 
      2 => 4, 2 => 5, 
      3 => 4);

$graph = Graph::Directed->new()->add(@E);

# Reachable nodes always come after the current node in a topological
# sort. 
@L = topsort($graph);
TEST2: while ($node = shift(@L)) {
    @T = $graph->reachable_from($node);
    foreach my $temp ($node,@L) {
	@T = grep($_ ne $temp, @T);
    }
    last TEST2 unless @T == 0;
}

if (@T > 0) {
    print "not ok 2\n";
} else {
    print "ok 2\n";
}
