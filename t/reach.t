
#                              -*- Mode: Perl -*- 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
 
######################### We start with some black magic to print on failure.
 
use lib './lib';
 
use Data::Dumper;

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Graph::Directed;
$loaded = 1;
print "ok 1\n";
 
######################### End of black magic.
 
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

@E = (1 => 2, 1 => 3, 2 => 4, 3 => 4, 4 => 2);

$graph = Graph::Directed->new()->add(@E);

@N = (2);
@R = (4,2);

@T = $graph->reachable_from(@N);
if (@T > 0) {
    while ($node = shift @R) { @T = grep ($_ ne $node, @T) }
    print (@T > 0 || @R > 0 ? "not ok 2 (@T != @R)\n" : "ok 2\n");
} else {
    print "not ok 2 (@T != @R)\n";
}
