#                              -*- Mode: Perl -*- 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
 
######################### We start with some black magic to print on failure.
 
use lib './lib';
 
use Data::Dumper;

BEGIN { $| = 1; print "1..8\n"; }
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

if (ref $graph eq "Graph::Directed") {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

#
# Testing edge functions.
# We test both positive and negative cases.
while (($a = shift @E) && ($b = shift @E)) {
    do { print "not ok 3\n"; last } unless $graph->edge($a,$b);
}
print "ok 3\n" unless @E > 0;

@E = (1 => 4, 4 => 3, 5 => 5);
while (($a = shift @E) && ($b = shift @E)) {
    do { print "not ok 4\n"; last } if $graph->edge($a,$b);
}
print "ok 4\n" unless @E > 0;

#
# Testing nodes function.
# We test both positive and negative cases.
@N = (1,2,3,4);
while ($node = shift @N) {
    unless (grep($_ eq $node, $graph->nodes())) {
	print "not ok 5\n";
	last;
    }
}
print "ok 5\n" unless @N > 0;

@N = (5,6,7,8);
while ($node = shift @N) {
    if (grep($_ eq $node, $graph->nodes())) {
	print "not ok 6\n";
	last;
    }
}
print "ok 6\n" unless @N > 0;

#
# Testing successor methods.
@N = (1);
@S = (3,2);			# Successors of @N

@T = $graph->succ(@N);
if (@T > 0) {
    while ($node = shift @S) { @T = grep ($_ ne $node, @T) }
    print (@T > 0 || @S > 0 ? "not ok 7 (@T != @S)\n" : "ok 7\n");
} else {
    print "not ok 7 (@T != @S)\n";
}

#
# Testing predecessor methods.
@N = (2);
@S = (1,4);			# Successors of @N

@T = $graph->pred(@N);
if (@T > 0) {
    while ($node = shift @S) { @T = grep ($_ ne $node, @T) }
    print (@T > 0 || @S > 0 ? "not ok 8 ([@T] != [@S])\n" : "ok 8\n");
} else {
    print "not ok 8 ([@T] != [@S])\n";
}
