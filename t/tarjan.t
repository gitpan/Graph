#                              -*- Mode: Perl -*- 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
 
######################### We start with some black magic to print on failure.
 
use lib './lib';
 
use Data::Dumper;

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Graph::Directed qw(scc);
$loaded = 1;
print "ok 1\n";
 
######################### End of black magic.
 
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

@E = (1 => 2, 1 => 3, 2 => 4, 3 => 4, 4 => 2);

$graph = Graph::Directed->new()->add(@E);

# Compare two lists lexiographically.
sub lcmp {
    if (@$a != @$b) {
	return @$a <=> @$b;
    }

    # The lists have the same length. 
    # Find the first place where the lists differ.
    my $i = 0;
    while ($a->[$i] eq $b->[$i]) {
	++$i;
    }

    if ($i != @$a) {
	return $a->[$i] cmp $b->[$i];
    } else {
	return 0;		# The lists were equivalent
    }
}

# testing Tarjan's algorithm.
@SCC = ([3], [1], [4,2]);
#@SCC = ([3,1], [4,2]);		# Not the SCCs of the graph
@T = scc($graph);

# Sort the lists to obtain a canonical form
foreach my $scc (@SCC) {
    @$scc = sort { $a cmp $b } @$scc;
}
foreach my $scc (@T) {
    @$scc = sort { $a cmp $b } @$scc;
}
@SCC = sort lcmp @SCC;
@T = sort lcmp @T;

TEST2: while (($one = shift(@T)) && ($two = shift(@SCC))) {
    if (@$one > 0) {
	while ($node = shift @$two) { @$one = grep ($_ ne $node, @$one) }
	if (@$one > 0 || @$two > 0) {
	    print "not ok 2 (@$one != @$two)\n";
	    push(@T,'dummy');
	    last TEST2;
	}
    } else {
	print "not ok 2 (@$one != @$two)\n";
	push(@T,'dummy');
	last TEST2;
    }
}
if ( @T == 0 && @SCC == 0) {
    print "ok 2\n";
} else {
    print "not ok 2 ([@T] and [@SCC] not both empty)\n";
}

